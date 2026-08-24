import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/wifi_sync_service.dart';
import 'academic_assessments_screen.dart';
import 'academic_dashboard_screen.dart';
import 'academic_management_screen.dart';
import 'academic_simulations_screen.dart';
import 'academic_summaries_screen.dart';
import 'settings_screen.dart';
import 'studies_extra_tabs.dart';
import 'studies_screen.dart';
import 'wifi_sync_screen.dart';

class AcademicShellScreen extends StatefulWidget {
  const AcademicShellScreen({
    required this.store,
    required this.wifi,
    super.key,
  });

  final AppStore store;
  final WifiSyncService wifi;

  @override
  State<AcademicShellScreen> createState() => _AcademicShellScreenState();
}

class _AcademicShellScreenState extends State<AcademicShellScreen> {
  int selectedIndex = 0;

  static const destinations = <_AcademicDestination>[
    _AcademicDestination(
      label: 'Menu principal',
      title: 'Visão acadêmica',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _AcademicDestination(
      label: 'Resumos',
      title: 'Resumos',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
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
      label: 'Flashcards',
      title: 'Flashcards',
      icon: Icons.style_outlined,
      selectedIcon: Icons.style,
    ),
    _AcademicDestination(
      label: 'Foco',
      title: 'Sessões de foco',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
    ),
    _AcademicDestination(
      label: 'Organização',
      title: 'Organização acadêmica',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
  ];

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
      AcademicSummariesScreen(store: widget.store),
      AcademicSimulationsScreen(store: widget.store),
      AcademicAssessmentsScreen(store: widget.store),
      StudyFlashcardsPage(store: widget.store),
      StudyFocusTab(store: widget.store),
      AcademicManagementScreen(store: widget.store),
    ];
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        drawer: desktop
            ? null
            : Drawer(
                width: 300,
                child: _AcademicSidebar(
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
                      SettingsScreen(store: widget.store, wifi: widget.wifi),
                    );
                  },
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
              onPressed: () =>
                  _open(SettingsScreen(store: widget.store, wifi: widget.wifi)),
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Row(
          children: <Widget>[
            if (desktop)
              SizedBox(
                width: 286,
                child: _AcademicSidebar(
                  selectedIndex: selectedIndex,
                  destinations: destinations,
                  onSelect: _select,
                  onSync: () => _open(
                    WifiSyncScreen(store: widget.store, wifi: widget.wifi),
                  ),
                  onSettings: () => _open(
                    SettingsScreen(store: widget.store, wifi: widget.wifi),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademicSidebar extends StatelessWidget {
  const _AcademicSidebar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
    required this.onSync,
    required this.onSettings,
  });

  final int selectedIndex;
  final List<_AcademicDestination> destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onSync;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF091326),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border)),
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
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFFA45AFF), Color(0xFF5334E3)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: .28),
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
                    const Expanded(
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
                            'Sistemas de Informação',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: destinations.length,
                  itemBuilder: (_, index) {
                    final item = destinations[index];
                    final selected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.purple.withValues(
                          alpha: .17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selected
                                ? AppColors.purple.withValues(alpha: .55)
                                : Colors.transparent,
                          ),
                        ),
                        leading: Icon(
                          selected ? item.selectedIcon : item.icon,
                          color:
                              selected ? AppColors.purple : AppColors.textMuted,
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
