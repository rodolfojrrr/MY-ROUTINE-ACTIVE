import 'package:flutter/material.dart';

import '../core/app_appearance.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';
import 'conflicts_screen.dart';
import 'recycle_bin_screen.dart';
import 'wifi_sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.store,
    required this.wifi,
    this.appearance,
    this.onLogout,
    super.key,
  });

  final AppStore store;
  final WifiSyncService wifi;
  final AppAppearanceController? appearance;
  final Future<void> Function()? onLogout;

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
                      if (appearance != null) ...<Widget>[
                        _AppearanceSettings(controller: appearance!),
                        const SizedBox(height: 12),
                      ],
                      _SettingsCard(
                        icon: Icons.sync,
                        color: AppColors.green,
                        title: 'Sincronizar pela mesma rede Wi‑Fi',
                        subtitle:
                            'Transfira banco e imagens entre PC e celular nos dois sentidos.',
                        action: 'Abrir',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WifiSyncScreen(store: store, wifi: wifi),
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
                        color: AppColors.primary,
                        title: 'Importar e mesclar backup',
                        subtitle:
                            'Faz uma cópia automática antes e mescla por ID e data de edição.',
                        action: 'Importar',
                        onTap: () => importBackup(context),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.account_circle_outlined,
                        color: AppColors.orange,
                        title:
                            store.activeAccount?.displayName ?? 'Conta local',
                        subtitle:
                            '@${store.activeAccount?.username ?? 'usuário'} • dados isolados neste perfil',
                        action: onLogout == null ? 'Ativa' : 'Trocar',
                        onTap: onLogout == null
                            ? () {}
                            : () async {
                                Navigator.of(context).pop();
                                await onLogout!();
                              },
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        icon: Icons.restore_from_trash_outlined,
                        color: AppColors.green,
                        title: 'Lixeira de segurança',
                        subtitle:
                            '${store.deletedRecords().length} item(ns) recuperável(is). Exclusões nunca somem imediatamente.',
                        action: 'Abrir',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RecycleBinScreen(store: store),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (store.conflictCount > 0)
                        _SettingsCard(
                          icon: Icons.merge_type,
                          color: AppColors.orange,
                          title:
                              '${store.conflictCount} conflito(s) preservado(s)',
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              'ID deste aparelho: ${store.deviceId}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Conflitos preservados: ${store.conflictCount}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
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

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings({required this.controller});

  final AppAppearanceController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.palette_outlined),
                SizedBox(width: 9),
                Text(
                  'Cor do aplicativo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'A organização não muda; escolha a identidade que deixa o estudo mais agradável para você.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppAccentPalette.values.map((palette) {
                final selected = controller.palette == palette;
                return Semantics(
                  selected: selected,
                  button: true,
                  label: 'Tema ${palette.label}',
                  child: InkWell(
                    onTap: () => controller.select(palette),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 128,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? palette.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[palette.light, palette.dark],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              palette.label,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconWidget = Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          );
          final textWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          );
          final actions = <Widget>[
            FilledButton.tonal(onPressed: onTap, child: Text(action)),
          ];
          if (constraints.maxWidth < 590) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    iconWidget,
                    const SizedBox(width: 13),
                    Expanded(child: textWidget),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions),
              ],
            );
          }
          return Row(
            children: <Widget>[
              iconWidget,
              const SizedBox(width: 14),
              Expanded(child: textWidget),
              ...actions,
            ],
          );
        },
      ),
    );
  }
}
