import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({
    required this.store,
    this.embedded = false,
    super.key,
  });

  final AppStore store;
  final bool embedded;

  Future<void> _restoreAll(BuildContext context) async {
    final items = store.deletedRecords();
    for (final item in items) {
      await store.restore(item.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${items.length} item(ns) restaurado(s).')),
      );
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir definitivamente'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _purge(BuildContext context, SyncEntity item) async {
    final confirmed = await _confirm(
      context,
      title: 'Excluir definitivamente?',
      message:
          '“${_titleFor(item)}” não poderá mais ser restaurado. A exclusão também será sincronizada com seus outros aparelhos.',
    );
    if (!confirmed) return;
    await store.purge(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item excluído definitivamente.')),
      );
    }
  }

  Future<void> _empty(BuildContext context) async {
    final items = store.deletedRecords();
    final confirmed = await _confirm(
      context,
      title: 'Esvaziar a lixeira?',
      message:
          'Os ${items.length} itens serão excluídos definitivamente e não poderão ser restaurados.',
    );
    if (!confirmed) return;
    for (final item in items) {
      await store.purge(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final items = store.deletedRecords();
        final body = AcademicPageBody(
          children: <Widget>[
            PageIntro(
              eyebrow: 'Proteção contra perda acidental',
              title: 'Registros excluídos',
              subtitle:
                  'Excluir remove o item das telas e sincroniza essa decisão, mas mantém uma cópia recuperável no banco e no backup.',
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            if (items.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _restoreAll(context),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar tudo'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('empty-recycle-bin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                    ),
                    onPressed: () => _empty(context),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Esvaziar lixeira'),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.delete_sweep_outlined,
                title: 'A lixeira está vazia',
                message:
                    'Itens removidos aparecerão aqui para você poder recuperá-los.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _iconFor(item.type),
                        color: AppColors.primary,
                      ),
                      title: Text(
                        _titleFor(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${_typeLabel(item.type)} • excluído em ${_date(item.deletedAtMs)}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Restaurar',
                            onPressed: () async {
                              await store.restore(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item restaurado.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            key: Key('purge-${item.id}'),
                            tooltip: 'Excluir definitivamente',
                            color: AppColors.red,
                            onPressed: () => _purge(context, item),
                            icon: const Icon(Icons.delete_forever_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
        if (embedded) return body;
        return Scaffold(
          appBar: AppBar(title: const Text('Lixeira de segurança')),
          body: body,
        );
      },
    );
  }
}

String _titleFor(SyncEntity item) {
  for (final key in const <String>[
    'title',
    'name',
    'question',
    'front',
    'description',
  ]) {
    final value = item.payload[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return 'Item sem título';
}

String _typeLabel(String type) => switch (type) {
      EntityTypes.semester => 'Período ou curso',
      EntityTypes.subject => 'Matéria',
      EntityTypes.studyContent => 'Conteúdo',
      EntityTypes.studyNote => 'Resumo',
      EntityTypes.studyQuestion => 'Questão',
      EntityTypes.flashcard => 'Flashcard',
      EntityTypes.exam => 'Avaliação',
      EntityTypes.dailyStudyGoal => 'Meta diária',
      EntityTypes.weeklyStudyPlan => 'Cronograma semanal',
      EntityTypes.kanbanTask => 'Atividade do Kanban',
      EntityTypes.codeProject => 'Projeto da IDE',
      EntityTypes.codeFile => 'Arquivo de código',
      EntityTypes.contentAsset => 'Imagem ou anexo de conteúdo',
      _ => 'Registro acadêmico',
    };

IconData _iconFor(String type) => switch (type) {
      EntityTypes.studyNote => Icons.description_outlined,
      EntityTypes.codeProject || EntityTypes.codeFile => Icons.code,
      EntityTypes.contentAsset => Icons.attach_file_rounded,
      EntityTypes.kanbanTask => Icons.view_kanban_outlined,
      EntityTypes.dailyStudyGoal => Icons.flag_outlined,
      EntityTypes.exam => Icons.event_outlined,
      _ => Icons.restore_from_trash_outlined,
    };

String _date(int? milliseconds) {
  if (milliseconds == null) return 'data desconhecida';
  return DateFormat('dd/MM/yyyy HH:mm').format(
    DateTime.fromMillisecondsSinceEpoch(milliseconds),
  );
}
