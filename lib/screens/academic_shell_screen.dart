import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_appearance.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/study_timer_controller.dart';
import '../core/wifi_sync_service.dart';
import 'academic_assessments_screen.dart';
import 'academic_courses_screen.dart';
import 'academic_dashboard_screen.dart';
import 'academic_faculty_screen.dart';
import 'academic_simulations_screen.dart';
import 'academic_summaries_screen.dart';
import 'code_workspace_screen.dart';
import 'daily_goals_screen.dart';
import 'pdf_tools_screen.dart';
import 'recycle_bin_screen.dart';
import 'settings_screen.dart';
import 'studies_screen.dart';
import 'study_kanban_screen.dart';
import 'wifi_sync_screen.dart';

class AcademicShellScreen extends StatefulWidget {
  const AcademicShellScreen({
    required this.store,
    required this.wifi,
    this.appearance,
    this.studyTimer,
    this.onLogout,
    super.key,
  });

  final AppStore store;
  final WifiSyncService wifi;
  final AppAppearanceController? appearance;
  final StudyTimerController? studyTimer;
  final Future<void> Function()? onLogout;

  @override
  State<AcademicShellScreen> createState() => _AcademicShellScreenState();
}

class _AcademicShellScreenState extends State<AcademicShellScreen> {
  int selectedIndex = 0;
  bool desktopSidebarCollapsed = false;
  late final AppAppearanceController appearance;
  late final StudyTimerController studyTimer;
  late final bool ownsAppearance;
  late final bool ownsStudyTimer;

  static const destinations = <_AcademicDestination>[
    _AcademicDestination(
      label: 'Menu principal',
      title: 'Visão acadêmica',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _AcademicDestination(
      label: 'Faculdade',
      title: 'Faculdade',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    _AcademicDestination(
      label: 'Cursos',
      title: 'Cursos',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
    ),
    _AcademicDestination(
      label: 'Metas e foco',
      title: 'Metas diárias e foco',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
    ),
    _AcademicDestination(
      label: 'Resumos',
      title: 'Resumos',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
    ),
    _AcademicDestination(
      label: 'Kanban',
      title: 'Kanban de estudos',
      icon: Icons.view_kanban_outlined,
      selectedIcon: Icons.view_kanban,
    ),
    _AcademicDestination(
      label: 'Simulados',
      title: 'Questões e simulados',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    _AcademicDestination(
      label: 'Avaliações',
      title: 'Avaliações',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
    ),
    _AcademicDestination(
      label: 'IDE de código',
      title: 'IDE acadêmica',
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal_rounded,
    ),
    _AcademicDestination(
      label: 'Flashcards',
      title: 'Flashcards',
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
    ),
    _AcademicDestination(
      label: 'Lixeira',
      title: 'Lixeira',
      icon: Icons.delete_outline_rounded,
      selectedIcon: Icons.delete_rounded,
    ),
    _AcademicDestination(
      label: 'Ferramentas PDF',
      title: 'Ferramentas PDF',
      icon: Icons.picture_as_pdf_outlined,
      selectedIcon: Icons.picture_as_pdf,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ownsAppearance = widget.appearance == null;
    ownsStudyTimer = widget.studyTimer == null;
    appearance = widget.appearance ?? AppAppearanceController(widget.store);
    studyTimer = widget.studyTimer ?? StudyTimerController(widget.store);
    if (ownsAppearance) unawaited(appearance.loadForActiveAccount());
    if (ownsStudyTimer) unawaited(studyTimer.initializeForActiveAccount());
    unawaited(_loadSidebarPreference());
  }

  Future<void> _loadSidebarPreference() async {
    if (widget.store.activeAccount == null) return;
    final saved = await widget.store.readUserPreference(
      'desktop_sidebar_collapsed',
    );
    if (mounted && saved != null) {
      setState(() => desktopSidebarCollapsed = saved == 'true');
    }
  }

  void _toggleDesktopSidebar() {
    setState(() => desktopSidebarCollapsed = !desktopSidebarCollapsed);
    if (widget.store.activeAccount != null) {
      unawaited(
        widget.store.writeUserPreference(
          'desktop_sidebar_collapsed',
          desktopSidebarCollapsed.toString(),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (ownsAppearance) appearance.dispose();
    if (ownsStudyTimer) studyTimer.dispose();
    super.dispose();
  }

  void _select(int index, {bool closeDrawer = false}) {
    if (closeDrawer) Navigator.of(context).pop();
    setState(() => selectedIndex = index);
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    final pages = <Widget>[
      AcademicDashboardScreen(
        store: widget.store,
        onOpenSection: (index) => setState(() => selectedIndex = index),
      ),
      AcademicFacultyScreen(store: widget.store),
      AcademicCoursesScreen(store: widget.store),
      DailyGoalsScreen(store: widget.store, timer: studyTimer),
      AcademicSummariesScreen(store: widget.store),
      StudyKanbanScreen(store: widget.store),
      AcademicSimulationsScreen(store: widget.store),
      AcademicAssessmentsScreen(store: widget.store),
      CodeWorkspaceScreen(store: widget.store),
      StudyFlashcardsPage(store: widget.store),
      RecycleBinScreen(store: widget.store, embedded: true),
      PdfToolsScreen(store: widget.store),
    ];
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.store, studyTimer]),
      builder: (context, _) => Scaffold(
        drawer: desktop
            ? null
            : Drawer(
                width: 300,
                child: _AcademicSidebar(
                  store: widget.store,
                  selectedIndex: selectedIndex,
                  destinations: destinations,
                  onSelect: (index) => _select(index, closeDrawer: true),
                  onSync: () {
                    Navigator.of(context).pop();
                    _open(
                      WifiSyncScreen(store: widget.store, wifi: widget.wifi),
                    );
                  },
                  onSettings: () {
                    Navigator.of(context).pop();
                    _open(
                      SettingsScreen(
                        store: widget.store,
                        wifi: widget.wifi,
                        appearance: appearance,
                        onLogout: widget.onLogout,
                      ),
                    );
                  },
                  onLogout: widget.onLogout,
                ),
              ),
        appBar: AppBar(
          title: Text(destinations[selectedIndex].title),
          actions: <Widget>[
            IconButton(
              tooltip: 'Sincronizar PC e celular',
              onPressed: () =>
                  _open(WifiSyncScreen(store: widget.store, wifi: widget.wifi)),
              icon: const Icon(Icons.sync),
            ),
            IconButton(
              tooltip: 'Configurações e backup',
              onPressed: () => _open(
                SettingsScreen(
                  store: widget.store,
                  wifi: widget.wifi,
                  appearance: appearance,
                  onLogout: widget.onLogout,
                ),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Row(
                children: <Widget>[
                  if (desktop)
                    SizedBox(
                      key: const Key('desktop-sidebar-frame'),
                      width: desktopSidebarCollapsed ? 84 : 286,
                      child: desktopSidebarCollapsed
                          ? _AcademicSidebarCompact(
                              selectedIndex: selectedIndex,
                              destinations: destinations,
                              onSelect: _select,
                              onExpand: _toggleDesktopSidebar,
                              onSync: () => _open(
                                WifiSyncScreen(
                                  store: widget.store,
                                  wifi: widget.wifi,
                                ),
                              ),
                              onSettings: () => _open(
                                SettingsScreen(
                                  store: widget.store,
                                  wifi: widget.wifi,
                                  appearance: appearance,
                                  onLogout: widget.onLogout,
                                ),
                              ),
                              onLogout: widget.onLogout,
                            )
                          : _AcademicSidebar(
                              store: widget.store,
                              selectedIndex: selectedIndex,
                              destinations: destinations,
                              onSelect: _select,
                              onCollapse: _toggleDesktopSidebar,
                              onSync: () => _open(
                                WifiSyncScreen(
                                  store: widget.store,
                                  wifi: widget.wifi,
                                ),
                              ),
                              onSettings: () => _open(
                                SettingsScreen(
                                  store: widget.store,
                                  wifi: widget.wifi,
                                  appearance: appearance,
                                  onLogout: widget.onLogout,
                                ),
                              ),
                              onLogout: widget.onLogout,
                            ),
                    ),
                  Expanded(
                    child: IndexedStack(index: selectedIndex, children: pages),
                  ),
                ],
              ),
            ),
            if (studyTimer.isActive && selectedIndex != 3)
              Positioned(
                right: 16,
                bottom: 16,
                child: _FloatingStudyTimer(
                  timer: studyTimer,
                  onTap: () => setState(() => selectedIndex = 3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingStudyTimer extends StatelessWidget {
  const _FloatingStudyTimer({required this.timer, required this.onTap});

  final StudyTimerController timer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: BoxConstraints(maxWidth: width < 520 ? width - 32 : 360),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.appSurfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                timer.isRunning ? Icons.play_arrow : Icons.pause,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      timer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${timer.formattedElapsed} • abrir temporizador',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicSidebar extends StatelessWidget {
  const _AcademicSidebar({
    required this.store,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
    required this.onSync,
    required this.onSettings,
    this.onCollapse,
    this.onLogout,
  });

  final AppStore store;
  final int selectedIndex;
  final List<_AcademicDestination> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onSync;
  final VoidCallback onSettings;
  final VoidCallback? onCollapse;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final account = store.activeAccount;
    return Material(
      color: AppColors.appSidebar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.appBorder)),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            AppColors.primaryLight,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .28),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Smart Routine SI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            account?.displayName ?? 'Sistemas de Informação',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onCollapse != null) ...<Widget>[
                      const SizedBox(width: 4),
                      IconButton(
                        key: const Key('desktop-sidebar-collapse'),
                        tooltip: 'Recolher menu lateral',
                        onPressed: onCollapse,
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ESTUDOS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('academic-sidebar-destinations'),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: destinations.length,
                  itemBuilder: (_, index) {
                    final item = destinations[index];
                    final selected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: .17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary.withValues(alpha: .55)
                                : Colors.transparent,
                          ),
                        ),
                        leading: Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : AppColors.textMuted,
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                        onTap: () => onSelect(index),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const Icon(Icons.sync, color: AppColors.green),
                      title: const Text('Sincronização Wi‑Fi'),
                      subtitle: const Text(
                        'PC ↔ celular',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      onTap: onSync,
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textMuted,
                      ),
                      title: const Text('Dados e configurações'),
                      onTap: onSettings,
                    ),
                    if (onLogout != null)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.orange,
                        ),
                        title: const Text('Trocar de usuário'),
                        onTap: () => onLogout!(),
                      ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: .22),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.cloud_off_outlined,
                            color: AppColors.green,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dados somente locais',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademicSidebarCompact extends StatelessWidget {
  const _AcademicSidebarCompact({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
    required this.onExpand,
    required this.onSync,
    required this.onSettings,
    this.onLogout,
  });

  final int selectedIndex;
  final List<_AcademicDestination> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onExpand;
  final VoidCallback onSync;
  final VoidCallback onSettings;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appSidebar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.appBorder)),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.primaryLight,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              const SizedBox(height: 5),
              IconButton(
                key: const Key('desktop-sidebar-expand'),
                tooltip: 'Expandir menu lateral',
                onPressed: onExpand,
                icon: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  key: const Key('academic-sidebar-compact-destinations'),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: destinations.length,
                  itemBuilder: (_, index) {
                    final item = destinations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: _CompactSidebarButton(
                        tooltip: item.label,
                        icon: selectedIndex == index
                            ? item.selectedIcon
                            : item.icon,
                        selected: selectedIndex == index,
                        onTap: () => onSelect(index),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: <Widget>[
                    _CompactSidebarButton(
                      tooltip: 'Sincronização Wi‑Fi',
                      icon: Icons.sync,
                      iconColor: AppColors.green,
                      onTap: onSync,
                    ),
                    _CompactSidebarButton(
                      tooltip: 'Dados e configurações',
                      icon: Icons.settings_outlined,
                      onTap: onSettings,
                    ),
                    if (onLogout != null)
                      _CompactSidebarButton(
                        tooltip: 'Trocar de usuário',
                        icon: Icons.logout,
                        iconColor: AppColors.orange,
                        onTap: () => onLogout!(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSidebarButton extends StatelessWidget {
  const _CompactSidebarButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.iconColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color =
        iconColor ?? (selected ? AppColors.primary : AppColors.textMuted);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: selected
              ? AppColors.primary.withValues(alpha: .17)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: .55)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 46,
              child: Icon(icon, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademicDestination {
  const _AcademicDestination({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}
