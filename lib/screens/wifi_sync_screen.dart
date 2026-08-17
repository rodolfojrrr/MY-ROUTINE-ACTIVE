import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';

class WifiSyncScreen extends StatefulWidget {
  const WifiSyncScreen({required this.store, required this.wifi, super.key});

  final AppStore store;
  final WifiSyncService wifi;

  @override
  State<WifiSyncScreen> createState() => _WifiSyncScreenState();
}

class _WifiSyncScreenState extends State<WifiSyncScreen> {
  final host = TextEditingController();
  final port = TextEditingController(text: '8765');
  final code = TextEditingController();
  bool connecting = false;

  @override
  void dispose() {
    host.dispose();
    port.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    if (host.text.trim().isEmpty || code.text.trim().length != 6) return;
    setState(() => connecting = true);
    try {
      final result = await widget.wifi.connectAndSync(
        host: host.text.trim(),
        port: int.tryParse(port.text) ?? 8765,
        code: code.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sincronizado: ${result.changed} alterações; ${result.conflicts} conflitos preservados.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível sincronizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.wifi,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Sincronização Wi‑Fi local')),
        body: PremiumBackground(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const PageIntro(
                        eyebrow: 'Sem internet e sem nuvem',
                        title: 'PC e celular na mesma rede',
                        subtitle:
                            'No PC, abra uma sessão temporária. No celular, informe IP e código. Os dois aparelhos terminam com a versão mesclada.',
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.green.withValues(alpha: .35)),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(Icons.security, color: AppColors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Antes de cada sincronização, o app salva um backup automático. Registros são mesclados por UUID e data de edição; conflitos ficam registrados.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final left = _ServerCard(wifi: widget.wifi);
                          final right = _ClientCard(
                            host: host,
                            port: port,
                            code: code,
                            connecting: connecting,
                            connect: connect,
                          );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(child: left),
                                    const SizedBox(width: 16),
                                    Expanded(child: right),
                                  ],
                                )
                              : Column(
                                  children: <Widget>[
                                    left,
                                    const SizedBox(height: 16),
                                    right,
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 18),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Checklist rápido',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 10),
                            const Text('1. Conecte PC e celular ao mesmo roteador Wi‑Fi.'),
                            const Text('2. No PC, clique em “Abrir sessão no PC”.'),
                            const Text('3. Se o Windows perguntar, permita o app em redes privadas.'),
                            const Text('4. Digite no celular o IP e o código mostrados no PC.'),
                            const Text('5. Clique em “Sincronizar agora” e aguarde a confirmação.'),
                            const SizedBox(height: 10),
                            Text(
                              'Este aparelho: ${Platform.isWindows ? 'Windows' : Platform.isAndroid ? 'Android' : Platform.operatingSystem} • Status: ${widget.wifi.status}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.wifi});

  final WifiSyncService wifi;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppColors.blue.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.computer, color: AppColors.blue, size: 42),
          const SizedBox(height: 12),
          const Text(
            '1. No computador',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'O servidor só fica aberto durante esta sessão e aceita o código exibido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          if (wifi.isServing) ...<Widget>[
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: wifi.qrPayload,
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              'IP: ${wifi.localIp}\nPorta: ${wifi.port}\nCódigo: ${wifi.pairingCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, height: 1.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: wifi.stopServer,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Encerrar sessão'),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await wifi.startServer();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Falha ao abrir a sessão: $error')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Abrir sessão no PC'),
            ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.host,
    required this.port,
    required this.code,
    required this.connecting,
    required this.connect,
  });

  final TextEditingController host;
  final TextEditingController port;
  final TextEditingController code;
  final bool connecting;
  final VoidCallback connect;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppColors.green.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.phone_android, color: AppColors.green, size: 42),
          const SizedBox(height: 12),
          const Text(
            '2. No celular',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: host,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'IP do PC',
              hintText: '192.168.0.10',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: port,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Porta'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: connecting ? null : connect,
            icon: connecting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('Sincronizar agora'),
          ),
        ],
      ),
    );
  }
}
