import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';
import 'calendar_screen.dart';
import 'conflicts_screen.dart';
import 'reminders_screen.dart';
import 'search_screen.dart';
import 'wifi_sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.store, required this.wifi, super.key});

  final AppStore store;
  final WifiSyncService wifi;

  void message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> exportBackup(BuildContext context) async {
    try {
      final path = await FileTransferService.exportBackup(store);
      if (context.mounted && path != null) {
        message(context, 'Backup .mra salvo com sucesso.');
      }
    } catch (error) {
      if (context.mounted) message(context, 'Falha ao exportar: $error');
    }
  }

  Future<void> importBackup(BuildContext context) async {
    try {
      final result = await FileTransferService.importBackup(store);
      if (context.mounted && result != null) {
        message(
          context,
          'Importação concluída: ${result.changed} alterações e ${result.conflicts} conflitos preservados.',
        );
      }
    } catch (error) {
      if (context.mounted) message(context, 'Falha ao importar: $error');
    }
  }

  Future<void> configurePin(BuildContext context) async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Definir PIN local'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'O PIN protege a abertura neste aparelho. Ele não cria conta e não sai do dispositivo.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: first,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Novo PIN'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: second,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (first.text.length >= 4 && first.text == second.text) {
                Navigator.pop(dialogContext, first.text);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    if (result != null) {
      await store.setPin(result);
      if (context.mounted) message(context, 'PIN local atualizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: PremiumBackground(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const PageIntro(
                        eyebrow: 'Controle local',
                        title: 'Dados, segurança e transferência',
                        subtitle:
                            'O banco fica no aparelho. Backups e sincronização só acontecem quando você manda.',
                      ),
                      const SizedBox(height: 20),
                      _SettingsCard(
                        icon: Icons.sync,
                        color: AppColors.green,
                        title: 'Sincronizar pela mesma rede Wi‑Fi',
                        subtitle:
                            'Transfira banco e imagens entre PC e celular nos dois sentidos.',
                        action: 'Abrir',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => WifiSyncScreen(store: store, wifi: wifi),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.file_upload_outlined,
                        color: AppColors.blue,
                        title: 'Exportar backup .mra',
                        subtitle:
                            'Cria um arquivo portátil com todos os registros e imagens.',
                        action: 'Exportar',
                        onTap: () => exportBackup(context),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.file_download_outlined,
                        color: AppColors.purple,
                        title: 'Importar e mesclar backup',
                        subtitle:
                            'Faz uma cópia automática antes e mescla por ID e data de edição.',
                        action: 'Importar',
                        onTap: () => importBackup(context),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.green,
                        title: 'Lembretes locais',
                        subtitle:
                            'Crie lembretes e ative notificações no Android.',
                        action: 'Abrir',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RemindersScreen(store: store),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.blue,
                        title: 'Agenda geral',
                        subtitle:
                            'Veja provas, faturas, empréstimos e lembretes por data.',
                        action: 'Abrir',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CalendarScreen(store: store),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.search,
                        color: AppColors.purple,
                        title: 'Busca geral',
                        subtitle:
                            'Pesquise registros de todos os módulos no banco local.',
                        action: 'Buscar',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SearchScreen(store: store),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<bool>(
                        future: store.hasPin(),
                        builder: (context, snapshot) {
                          final enabled = snapshot.data == true;
                          return _SettingsCard(
                            icon: Icons.lock_outline,
                            color: AppColors.orange,
                            title: enabled ? 'PIN local ativado' : 'Proteger com PIN local',
                            subtitle: enabled
                                ? 'Você pode trocar ou remover a proteção deste aparelho.'
                                : 'Sem e-mail, sem conta e sem nuvem.',
                            action: enabled ? 'Trocar' : 'Ativar',
                            onTap: () => configurePin(context),
                            secondaryAction: enabled
                                ? () async {
                                    await store.clearPin();
                                    if (context.mounted) {
                                      message(context, 'PIN removido deste aparelho.');
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (store.conflictCount > 0)
                        _SettingsCard(
                          icon: Icons.merge_type,
                          color: AppColors.orange,
                          title: '${store.conflictCount} conflito(s) preservado(s)',
                          subtitle:
                              'Revise as duas versões mantidas pela sincronização.',
                          action: 'Revisar',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ConflictsScreen(store: store),
                            ),
                          ),
                        ),
                      if (store.conflictCount > 0) const SizedBox(height: 12),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Diagnóstico local',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              'ID deste aparelho: ${store.deviceId}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Conflitos preservados: ${store.conflictCount}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Armazenamento: SQLite local • Nuvem: desativada • Telemetria: nenhuma',
                              style: TextStyle(color: AppColors.textMuted),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.secondaryAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final VoidCallback? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (secondaryAction != null)
            TextButton(onPressed: secondaryAction, child: const Text('Remover')),
          const SizedBox(width: 5),
          FilledButton.tonal(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

