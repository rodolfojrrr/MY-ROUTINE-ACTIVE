import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'app_store.dart';
import 'backup_service.dart';
import 'sync_entity.dart';

class WifiSyncService extends ChangeNotifier {
  WifiSyncService(this.store);

  final AppStore store;
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;
  String _pairingCode = '';
  String _localIp = '';
  String _status = 'Parado';
  int _successfulSyncs = 0;

  bool get isServing => _server != null;
  String get pairingCode => _pairingCode;
  String get localIp => _localIp;
  int get port => _server?.port ?? 0;
  String get status => _status;
  int get successfulSyncs => _successfulSyncs;
  String get qrPayload =>
      'mra://sync?host=$_localIp&port=$port&code=$_pairingCode';

  Future<void> startServer() async {
    if (_server != null) return;
    _pairingCode = (100000 + Random.secure().nextInt(900000)).toString();
    _localIp = await _discoverLanIp();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8765);
    _server!.idleTimeout = const Duration(minutes: 5);
    _subscription = _server!.listen(
      _handleRequest,
      onError: (Object error) {
        _status = 'Erro no servidor: $error';
        notifyListeners();
      },
    );
    _status = 'Aguardando o outro aparelho';
    notifyListeners();
  }

  Future<void> stopServer() async {
    await _subscription?.cancel();
    _subscription = null;
    await _server?.close(force: true);
    _server = null;
    _pairingCode = '';
    _status = 'Parado';
    notifyListeners();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Cache-Control', 'no-store');

    if (request.uri.path == '/health' && request.method == 'GET') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('My Routine Active local');
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
      notifyListeners();
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > 50 * 1024 * 1024) {
          throw const HttpException('Pacote maior que 50 MB.');
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
      notifyListeners();
    } catch (error) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Falha na sincronização: $error');
      await request.response.close();
      _status = 'Falha: $error';
      notifyListeners();
    }
  }

  Future<MergeResult> connectAndSync({
    required String host,
    required int port,
    required String code,
  }) async {
    _status = 'Conectando a $host…';
    notifyListeners();
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
      final response = await request.close().timeout(const Duration(minutes: 2));
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
      notifyListeners();
      return result;
    } catch (error) {
      _status = 'Falha: $error';
      notifyListeners();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _discoverLanIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final addresses = interfaces
        .expand((item) => item.addresses)
        .map((item) => item.address)
        .toList(growable: false);
    for (final prefix in const <String>['192.168.', '10.']) {
      for (final ip in addresses) {
        if (ip.startsWith(prefix)) return ip;
      }
    }
    for (final ip in addresses) {
      final parts = ip.split('.');
      final second = parts.length == 4 ? int.tryParse(parts[1]) : null;
      if (parts.first == '172' &&
          second != null &&
          second >= 16 &&
          second <= 31) {
        return ip;
      }
    }
    return addresses.isEmpty ? '127.0.0.1' : addresses.first;
  }

  @override
  void dispose() {
    unawaited(stopServer());
    super.dispose();
  }
}
