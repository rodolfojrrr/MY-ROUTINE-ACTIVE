import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../widgets/premium_widgets.dart';

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  late Future<List<Map<String, Object?>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.store.unresolvedConflicts();
  }

  void _reload() {
    setState(() => future = widget.store.unresolvedConflicts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conflitos de sincronização')),
      body: PremiumBackground(
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final conflicts = snapshot.data ?? <Map<String, Object?>>[];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 950),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const PageIntro(
                          eyebrow: 'Sincronização',
                          title: 'Conflitos preservados',
                          subtitle:
                              'Quando PC e celular alteram o mesmo registro, o aplicativo guarda as duas versões para auditoria em vez de apagar silenciosamente.',
                        ),
                        const SizedBox(height: 18),
                        if (conflicts.isEmpty)
                          const EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Nenhum conflito pendente',
                            message: 'A sincronização está limpa.',
                          )
                        else
                          ...conflicts.map((item) {
                            final created = DateTime.fromMillisecondsSinceEpoch(
                              (item['created_at'] as num? ?? 0).toInt(),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PremiumCard(
                                borderColor: AppColors.orange,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        const Icon(Icons.merge_type, color: AppColors.orange),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Registro ${item['entity_id'] ?? ''}',
                                            style: const TextStyle(fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        Text(DateFormat('dd/MM/yyyy HH:mm').format(created)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Versão vencedora: ${item['winner_device_id'] ?? ''}',
                                      style: const TextStyle(color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      title: const Text('Ver versões preservadas'),
                                      children: <Widget>[
                                        _JsonBox(label: 'Local', value: item['local_json']?.toString() ?? ''),
                                        const SizedBox(height: 8),
                                        _JsonBox(label: 'Remota', value: item['remote_json']?.toString() ?? ''),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.tonalIcon(
                                        onPressed: () async {
                                          await widget.store.resolveConflict((item['id'] as num).toInt());
                                          _reload();
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Marcar como revisado'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JsonBox extends StatelessWidget {
  const _JsonBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          SelectableText(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
