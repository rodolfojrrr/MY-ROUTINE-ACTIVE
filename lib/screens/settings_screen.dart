import 'package:flutter/material.dart';

import '../core/app_appearance.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pro_color_picker.dart';
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
              'Use uma identidade pronta ou monte cada camada do aplicativo do seu jeito.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppAccentPalette.values.map((palette) {
                final selected =
                    !controller.isCustom && controller.palette == palette;
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
                          color:
                              selected ? palette.primary : AppColors.appBorder,
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('open-advanced-color-editor'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _AdvancedAppearanceDialog(
                    controller: controller,
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  controller.isCustom
                      ? 'Editar meu tema personalizado'
                      : 'Abrir editor avançado de cores',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedAppearanceDialog extends StatefulWidget {
  const _AdvancedAppearanceDialog({required this.controller});

  final AppAppearanceController controller;

  @override
  State<_AdvancedAppearanceDialog> createState() =>
      _AdvancedAppearanceDialogState();
}

class _AdvancedAppearanceDialogState extends State<_AdvancedAppearanceDialog> {
  late AppVisualProfile profile;

  @override
  void initState() {
    super.initState();
    profile = widget.controller.profile;
  }

  void _change(AppVisualProfile value) => setState(() => profile = value);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editor avançado de cores'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ThemePreview(profile: profile),
              const SizedBox(height: 16),
              const Text(
                'Toque em qualquer item para usar seletor visual ou informar uma cor HEX.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 13),
              ProColorTile(
                title: 'Cor principal',
                subtitle: 'Botões, seleção, destaques e links',
                color: profile.primary,
                onChanged: (color) => _change(profile.copyWith(primary: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Cor secundária',
                subtitle: 'Ações complementares e indicadores positivos',
                color: profile.secondary,
                onChanged: (color) =>
                    _change(profile.copyWith(secondary: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Fundo geral',
                subtitle: 'Área principal de todas as páginas',
                color: profile.background,
                onChanged: (color) =>
                    _change(profile.copyWith(background: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Cartões e pastas',
                subtitle: 'Painéis, cartões e janelas do aplicativo',
                color: profile.surface,
                onChanged: (color) => _change(profile.copyWith(surface: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Campos e barras',
                subtitle: 'Campos de texto, ferramentas e superfícies elevadas',
                color: profile.surfaceRaised,
                onChanged: (color) =>
                    _change(profile.copyWith(surfaceRaised: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Bordas',
                subtitle: 'Contornos que organizam as áreas da interface',
                color: profile.border,
                onChanged: (color) => _change(profile.copyWith(border: color)),
              ),
              const SizedBox(height: 9),
              ProColorTile(
                title: 'Menu lateral',
                subtitle: 'Fundo exclusivo da navegação principal',
                color: profile.sidebar,
                onChanged: (color) => _change(profile.copyWith(sidebar: color)),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        OutlinedButton(
          onPressed: () async {
            await widget.controller.select(AppAccentPalette.blue);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Restaurar azul'),
        ),
        FilledButton.icon(
          key: const Key('save-custom-theme'),
          onPressed: () async {
            await widget.controller.customize(profile);
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar tema'),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.profile});

  final AppVisualProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: profile.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: profile.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 74,
            decoration: BoxDecoration(
              color: profile.sidebar,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(19),
              ),
              border: Border(right: BorderSide(color: profile.border)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.school_rounded, color: profile.primary),
                const SizedBox(height: 15),
                Icon(Icons.home_rounded, color: profile.primaryLight),
                const SizedBox(height: 15),
                const Icon(Icons.folder_rounded, color: Colors.white54),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 24,
                    width: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          profile.primaryLight,
                          profile.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: profile.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: profile.border),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.folder_rounded,
                              color: profile.primary,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: profile.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: profile.secondary),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: profile.secondary,
                              size: 30,
                            ),
                          ),
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
