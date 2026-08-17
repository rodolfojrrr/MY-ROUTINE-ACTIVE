import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';
import 'studies_screen.dart';
import 'training_screen.dart';
import 'wifi_sync_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.store, required this.wifi, super.key});

  final AppStore store;
  final WifiSyncService wifi;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final subjects = store.records(EntityTypes.subject).length;
        final plans = store.records(EntityTypes.workoutPlan).length;
        final cards = store.records(EntityTypes.card).length;
        return Scaffold(
          body: PremiumBackground(
            child: SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _Header(
                                onSync: () => _open(
                                  context,
                                  WifiSyncScreen(store: store, wifi: wifi),
                                ),
                                onSettings: () => _open(
                                  context,
                                  SettingsScreen(store: store, wifi: wifi),
                                ),
                              ),
                              const SizedBox(height: 42),
                              const PageIntro(
                                eyebrow: 'Sua central pessoal',
                                title: 'Boa rotina começa com clareza.',
                                subtitle:
                                    'Organize faculdade, evolução nos treinos e vida financeira em um único aplicativo — tudo salvo localmente.',
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final horizontal = constraints.maxWidth >= 820;
                                  final cardsList = <Widget>[
                                    _ModuleCard(
                                      title: 'Estudos',
                                      subtitle:
                                          'Aulas, matérias, provas, notas e flashcards',
                                      metric: '$subjects matérias',
                                      icon: Icons.school_outlined,
                                      colors: const <Color>[
                                        Color(0xFFA054FF),
                                        Color(0xFF5326CC),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        StudiesScreen(store: store),
                                      ),
                                    ),
                                    _ModuleCard(
                                      title: 'Treinos',
                                      subtitle:
                                          'Séries individuais, carga, falha e cronômetros',
                                      metric: '$plans fichas',
                                      icon: Icons.fitness_center,
                                      colors: const <Color>[
                                        Color(0xFFFF9A42),
                                        Color(0xFFC74731),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        TrainingScreen(store: store),
                                      ),
                                    ),
                                    _ModuleCard(
                                      title: 'Finanças',
                                      subtitle:
                                          'Salário fixo, cartões, parcelas, dívidas e empréstimos',
                                      metric: '$cards cartões',
                                      icon: Icons.account_balance_wallet_outlined,
                                      colors: const <Color>[
                                        Color(0xFF16D991),
                                        Color(0xFF087A66),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        FinanceScreen(store: store),
                                      ),
                                    ),
                                  ];
                                  if (horizontal) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: cardsList
                                          .map(
                                            (card) => Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 14,
                                                ),
                                                child: card,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  }
                                  return Column(
                                    children: cardsList
                                        .map(
                                          (card) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: card,
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 26),
                              PremiumCard(
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      color: AppColors.green,
                                      size: 34,
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Privacidade de verdade',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Nada é enviado para nuvem. Use o Wi‑Fi local somente quando quiser sincronizar PC e celular.',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Sincronizar',
                                      onPressed: () => _open(
                                        context,
                                        WifiSyncScreen(store: store, wifi: wifi),
                                      ),
                                      icon: const Icon(Icons.arrow_forward),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSync, required this.onSettings});

  final VoidCallback onSync;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.green, Color(0xFF0C8CA8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.green.withValues(alpha: .25),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'My Routine Active',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                'Seu dia, no seu controle',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Sincronização Wi‑Fi',
          onPressed: onSync,
          icon: const Icon(Icons.sync),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Configurações',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String metric;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Ink(
        height: 285,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.first.withValues(alpha: .22),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 29),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .82),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  metric,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
