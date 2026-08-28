import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'app_store.dart';
import 'backup_service.dart';
import 'sync_entity.dart';

class LanAddress {
  const LanAddress({required this.address, required this.interfaceName});

  final String address;
  final String interfaceName;

  String get label => '$address — $interfaceName';
}

class WifiSyncService extends ChangeNotifier {
  WifiSyncService(this.store);

  final AppStore store;
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;
  String _pairingCode = '';
  String _localIp = '';
  List<LanAddress> _lanAddresses = const <LanAddress>[];
  String _status = 'Parado';
  int _successfulSyncs = 0;
  bool _disposed = false;

  bool get isServing => _server != null;
  String get pairingCode => _pairingCode;
  String get localIp => _localIp;
  List<LanAddress> get lanAddresses => _lanAddresses;
  int get port => _server?.port ?? 0;
  String get status => _status;
  int get successfulSyncs => _successfulSyncs;
  String get qrPayload =>
      'mra://sync?host=$_localIp&port=$port&code=$_pairingCode';

  Future<void> startServer() async {
    if (_server != null) return;
    _pairingCode = (100000 + Random.secure().nextInt(900000)).toString();
    _lanAddresses = await _discoverLanAddresses();
    _localIp =
        _lanAddresses.isEmpty ? '127.0.0.1' : _lanAddresses.first.address;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8765);
    _server!.idleTimeout = const Duration(minutes: 5);
    _subscription = _server!.listen(
      _handleRequest,
      onError: (Object error) {
        _status = 'Erro no servidor: $error';
        _notifySafely();
      },
    );
    _status = 'Aguardando o outro aparelho';
    _notifySafely();
  }

  Future<void> stopServer() async {
    await _subscription?.cancel();
    _subscription = null;
    await _server?.close(force: true);
    _server = null;
    _pairingCode = '';
    _lanAddresses = const <LanAddress>[];
    _status = 'Parado';
    _notifySafely();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Cache-Control', 'no-store');

    if (request.uri.path == '/health' && request.method == 'GET') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Smart Routine SI local');
      await request.response.close();
      return;
    }

    if (request.uri.path != '/sync' || request.method != 'POST') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (request.headers.value('X-MRA-Code') != _pairingCode) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write('Código de pareamento inválido.');
      await request.response.close();
      return;
    }

    try {
      _status = 'Sincronizando…';
      _notifySafely();
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > 250 * 1024 * 1024) {
          throw const HttpException('Pacote maior que 250 MB.');
        }
      }
      final before = await store.exportBundle();
      await BackupService.createAutomaticSnapshot(
        before,
        reason: 'antes-da-sincronizacao-wifi',
      );
      final remote = BackupService.decodeBundle(bytes);
      final result = await store.mergeRemote(remote.entities);
      final responseBytes = await store.exportBundle();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.binary
        ..headers.set('X-MRA-Changed', result.changed.toString())
        ..add(responseBytes);
      await request.response.close();
      _successfulSyncs++;
      _status = 'Sincronização concluída';
      _notifySafely();
    } catch (error) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Falha na sincronização: $error');
      await request.response.close();
      _status = 'Falha: $error';
      _notifySafely();
    }
  }

  Future<MergeResult> connectAndSync({
    required String host,
    required int port,
    required String code,
  }) async {
    _status = 'Conectando a $host…';
    _notifySafely();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final localBytes = await store.exportBundle();
      final request = await client
          .postUrl(Uri.parse('http://$host:$port/sync'))
          .timeout(const Duration(seconds: 10));
      request.headers
        ..set('X-MRA-Code', code.trim())
        ..contentType = ContentType.binary
        ..contentLength = localBytes.length;
      request.add(localBytes);
      final response = await request.close().timeout(
            const Duration(minutes: 5),
          );
      final responseBytes = <int>[];
      await for (final chunk in response) {
        responseBytes.addAll(chunk);
      }
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(String.fromCharCodes(responseBytes));
      }
      await BackupService.createAutomaticSnapshot(
        localBytes,
        reason: 'antes-da-sincronizacao-wifi',
      );
      final remote = BackupService.decodeBundle(responseBytes);
      final result = await store.mergeRemote(remote.entities);
      _successfulSyncs++;
      _status = 'Sincronização concluída';
      _notifySafely();
      return result;
    } catch (error) {
      _status = 'Falha: $error';
      _notifySafely();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  void selectDisplayedIp(String address) {
    if (!_lanAddresses.any((item) => item.address == address)) return;
    _localIp = address;
    _notifySafely();
  }

  Future<List<LanAddress>> _discoverLanAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final candidates = <({LanAddress item, int score})>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address;
        if (!_isPrivateIpv4(ip)) continue;
        candidates.add((
          item: LanAddress(address: ip, interfaceName: interface.name),
          score: _addressScore(interface.name, ip),
        ));
      }
    }
    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.item.address.compareTo(b.item.address);
    });
    return candidates
        .map((candidate) => candidate.item)
        .toList(growable: false);
  }

  bool _isPrivateIpv4(String ip) {
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    final parts = ip.split('.');
    final second = parts.length == 4 ? int.tryParse(parts[1]) : null;
    return parts.first == '172' &&
        second != null &&
        second >= 16 &&
        second <= 31;
  }

  int _addressScore(String interfaceName, String ip) {
    final name = interfaceName.toLowerCase();
    var score = ip.startsWith('192.168.')
        ? 40
        : ip.startsWith('172.')
            ? 25
            : 10;
    if (name.contains('wi-fi') ||
        name.contains('wifi') ||
        name.contains('wlan') ||
        name.contains('wireless')) {
      score += 80;
    } else if (name.contains('ethernet')) {
      score += 60;
    }
    const virtualNames = <String>[
      'vethernet',
      'virtual',
      'vmware',
      'virtualbox',
      'hyper-v',
      'wsl',
      'docker',
      'vpn',
      'tailscale',
      'zerotier',
    ];
    if (virtualNames.any(name.contains)) score -= 150;
    return score;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stopServer());
    super.dispose();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }
}
