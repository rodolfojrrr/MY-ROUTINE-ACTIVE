import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class StudyKanbanScreen extends StatefulWidget {
  const StudyKanbanScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<StudyKanbanScreen> createState() => _StudyKanbanScreenState();
}

class _StudyKanbanScreenState extends State<StudyKanbanScreen> {
  String mobileStatus = 'pending';
  int retentionDays = 14;
  bool loadingRetention = true;

  List<_KanbanColumnInfo> get columns => <_KanbanColumnInfo>[
        _KanbanColumnInfo(
          id: 'pending',
          label: 'Pendentes',
          icon: Icons.radio_button_unchecked,
          color: AppColors.orange,
        ),
        _KanbanColumnInfo(
          id: 'doing',
          label: 'Fazendo',
          icon: Icons.timelapse,
          color: AppColors.primary,
        ),
        _KanbanColumnInfo(
          id: 'done',
          label: 'Concluídas',
          icon: Icons.check_circle_outline,
          color: AppColors.green,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadRetention();
  }

  Future<void> _loadRetention() async {
    final saved =
        await widget.store.readUserPreference('kanban_retention_days');
    retentionDays = int.tryParse(saved ?? '') ?? 14;
    await _cleanCompleted();
    if (mounted) setState(() => loadingRetention = false);
  }

  Future<void> _setRetention(int value) async {
    setState(() => retentionDays = value);
    await widget.store.writeUserPreference(
      'kanban_retention_days',
      value.toString(),
    );
    await _cleanCompleted();
  }

  Future<void> _cleanCompleted() async {
    if (retentionDays < 0) return;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    final expired = widget.store.records(EntityTypes.kanbanTask).where((item) {
      if (item.payload['status'] != 'done') return false;
      final completedAt = (item.payload['completedAt'] as num?)?.toInt();
      return completedAt != null && completedAt <= cutoff;
    }).toList();
    for (final item in expired) {
      await widget.store.remove(item.id);
    }
  }

  List<SyncEntity> _items(String status) {
    final result = widget.store
        .records(EntityTypes.kanbanTask)
        .where((item) => item.payload['status'] == status)
        .toList();
    result.sort((a, b) {
      final order = (a.payload['order'] as num? ?? 0).toInt().compareTo(
            (b.payload['order'] as num? ?? 0).toInt(),
          );
      if (order != 0) return order;
      return a.updatedAtMs.compareTo(b.updatedAtMs);
    });
    return result;
  }

  Future<void> _move(SyncEntity item, String status) async {
    if (item.payload['status'] == status) return;
    await widget.store.save(
      EntityTypes.kanbanTask,
      <String, dynamic>{
        ...item.payload,
        'status': status,
        'completedAt':
            status == 'done' ? DateTime.now().millisecondsSinceEpoch : null,
        'order': _items(status).length,
      },
      id: item.id,
    );
  }

  Future<void> _moveInside(SyncEntity item, int direction) async {
    final status = item.payload['status'] as String? ?? 'pending';
    final items = _items(status);
    final index = items.indexWhere((candidate) => candidate.id == item.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= items.length) return;
    final other = items[target];
    await widget.store.save(
      EntityTypes.kanbanTask,
      <String, dynamic>{...item.payload, 'order': target},
      id: item.id,
    );
    await widget.store.save(
      EntityTypes.kanbanTask,
      <String, dynamic>{...other.payload, 'order': index},
      id: other.id,
    );
  }

  Future<void> _delete(SyncEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir atividade?'),
        content: Text('“${item.payload['title'] ?? ''}” será removida.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.store.remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.store.records(EntityTypes.kanbanTask).length;
    final done = _items('done').length;
    return AcademicPageBody(
      children: <Widget>[
        PageIntro(
          eyebrow: 'Atividades visuais',
          title: 'Kanban de estudos',
          subtitle:
              'Mova trabalhos, cursos, projetos e revisões entre Pendentes, Fazendo e Concluídas. O prazo de limpeza evita acúmulo.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            MetricCard(
              label: 'Atividades',
              value: '$total',
              icon: Icons.view_kanban_outlined,
              color: AppColors.primary,
            ),
            MetricCard(
              label: 'Em andamento',
              value: '${_items('doing').length}',
              icon: Icons.timelapse,
              color: AppColors.orange,
            ),
            MetricCard(
              label: 'Concluídas visíveis',
              value: '$done',
              icon: Icons.task_alt,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _KanbanTaskDialog(store: widget.store),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nova atividade'),
            ),
            SizedBox(
              width: 290,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: retentionDays,
                decoration: const InputDecoration(
                  labelText: 'Manter concluídas por',
                  isDense: true,
                ),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem(
                    value: 0,
                    child: Text(
                      'Remover no mesmo dia',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(value: 3, child: Text('3 dias')),
                  DropdownMenuItem(value: 7, child: Text('7 dias')),
                  DropdownMenuItem(value: 14, child: Text('14 dias')),
                  DropdownMenuItem(value: 30, child: Text('30 dias')),
                  DropdownMenuItem(value: 90, child: Text('90 dias')),
                  DropdownMenuItem(
                    value: -1,
                    child: Text(
                      'Manter para sempre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: loadingRetention
                    ? null
                    : (value) {
                        if (value != null) _setRetention(value);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns
                    .expand(
                      (column) => <Widget>[
                        Expanded(
                          child: _KanbanColumn(
                            store: widget.store,
                            info: column,
                            items: _items(column.id),
                            onMove: _move,
                            onMoveInside: _moveInside,
                            onDelete: _delete,
                          ),
                        ),
                        if (column.id != 'done') const SizedBox(width: 12),
                      ],
                    )
                    .toList(),
              );
            }
            final selected = columns.firstWhere(
              (column) => column.id == mobileStatus,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns
                        .map(
                          (column) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: mobileStatus == column.id,
                              avatar: Icon(column.icon, size: 18),
                              label: Text(
                                '${column.label} (${_items(column.id).length})',
                              ),
                              onSelected: (_) =>
                                  setState(() => mobileStatus = column.id),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _KanbanColumn(
                  store: widget.store,
                  info: selected,
                  items: _items(selected.id),
                  onMove: _move,
                  onMoveInside: _moveInside,
                  onDelete: _delete,
                  compact: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.store,
    required this.info,
    required this.items,
    required this.onMove,
    required this.onMoveInside,
    required this.onDelete,
    this.compact = false,
  });

  final AppStore store;
  final _KanbanColumnInfo info;
  final List<SyncEntity> items;
  final Future<void> Function(SyncEntity, String) onMove;
  final Future<void> Function(SyncEntity, int) onMoveInside;
  final Future<void> Function(SyncEntity) onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final item = store.byId(details.data);
        if (item != null) onMove(item, info.id);
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: compact ? 220 : 400),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? AppColors.surface.withValues(alpha: .82)
              : info.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: candidates.isEmpty ? AppColors.border : info.color,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(info.icon, color: info.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: info.color.withValues(alpha: .14),
                  foregroundColor: info.color,
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Text(
                  candidates.isEmpty
                      ? 'Nenhuma atividade nesta coluna.'
                      : 'Solte aqui para mover.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...items.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: LongPressDraggable<String>(
                        data: entry.value.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 280,
                            child: Opacity(
                              opacity: .92,
                              child: _KanbanTaskCard(
                                store: store,
                                item: entry.value,
                                color: info.color,
                                onMove: onMove,
                                onMoveInside: onMoveInside,
                                onDelete: onDelete,
                                index: entry.key,
                                total: items.length,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: .25,
                          child: _KanbanTaskCard(
                            store: store,
                            item: entry.value,
                            color: info.color,
                            onMove: onMove,
                            onMoveInside: onMoveInside,
                            onDelete: onDelete,
                            index: entry.key,
                            total: items.length,
                          ),
                        ),
                        child: _KanbanTaskCard(
                          store: store,
                          item: entry.value,
                          color: info.color,
                          onMove: onMove,
                          onMoveInside: onMoveInside,
                          onDelete: onDelete,
                          index: entry.key,
                          total: items.length,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  const _KanbanTaskCard({
    required this.store,
    required this.item,
    required this.color,
    required this.onMove,
    required this.onMoveInside,
    required this.onDelete,
    required this.index,
    required this.total,
  });

  final AppStore store;
  final SyncEntity item;
  final Color color;
  final Future<void> Function(SyncEntity, String) onMove;
  final Future<void> Function(SyncEntity, int) onMoveInside;
  final Future<void> Function(SyncEntity) onDelete;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(item.payload['dueDate'] as String? ?? '');
    final overdue = due != null &&
        item.payload['status'] != 'done' &&
        due.isBefore(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.payload['title'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações',
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _KanbanTaskDialog(store: store, entity: item),
                    );
                  } else if (value == 'delete') {
                    onDelete(item);
                  } else {
                    onMove(item, value);
                  }
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(
                      value: 'pending', child: Text('Mover para Pendentes')),
                  PopupMenuItem(
                      value: 'doing', child: Text('Mover para Fazendo')),
                  PopupMenuItem(
                      value: 'done', child: Text('Mover para Concluídas')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          if ((item.payload['description'] as String? ?? '')
              .isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              item.payload['description'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              AcademicBadge(
                label: AcademicData.subjectName(
                  store,
                  item.payload['subjectId'] as String?,
                ),
              ),
              if (due != null)
                AcademicBadge(
                  label: DateFormat('dd/MM/yyyy').format(due),
                  color: overdue ? AppColors.red : AppColors.orange,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: 'Subir',
                onPressed: index == 0 ? null : () => onMoveInside(item, -1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Descer',
                onPressed:
                    index == total - 1 ? null : () => onMoveInside(item, 1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              const Spacer(),
              const Icon(Icons.drag_indicator, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _KanbanTaskDialog extends StatefulWidget {
  const _KanbanTaskDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_KanbanTaskDialog> createState() => _KanbanTaskDialogState();
}

class _KanbanTaskDialogState extends State<_KanbanTaskDialog> {
  late final TextEditingController title;
  late final TextEditingController description;
  String status = 'pending';
  String? subjectId;
  String? contentId;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    description = TextEditingController(
      text: widget.entity?.payload['description'] as String? ?? '',
    );
    status = widget.entity?.payload['status'] as String? ?? 'pending';
    subjectId = widget.entity?.payload['subjectId'] as String?;
    contentId = widget.entity?.payload['contentId'] as String?;
    dueDate =
        DateTime.tryParse(widget.entity?.payload['dueDate'] as String? ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title:
          Text(widget.entity == null ? 'Nova atividade' : 'Editar atividade'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Coluna'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'pending', child: Text('Pendentes')),
                  DropdownMenuItem(value: 'doing', child: Text('Fazendo')),
                  DropdownMenuItem(value: 'done', child: Text('Concluídas')),
                ],
                onChanged: (value) => setState(() => status = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: subjectId,
                decoration:
                    const InputDecoration(labelText: 'Matéria (opcional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Atividade geral'),
                  ),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.payload['name'] as String? ?? ''),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  subjectId = value;
                  contentId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: contentId,
                decoration:
                    const InputDecoration(labelText: 'Conteúdo (opcional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Conteúdo geral'),
                  ),
                  ...contents.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.payload['title'] as String? ?? ''),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => contentId = value),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  dueDate == null
                      ? 'Prazo opcional'
                      : DateFormat('dd/MM/yyyy').format(dueDate!),
                ),
                trailing: Wrap(
                  children: <Widget>[
                    if (dueDate != null)
                      IconButton(
                        onPressed: () => setState(() => dueDate = null),
                        icon: const Icon(Icons.close),
                      ),
                    IconButton(
                      onPressed: () async {
                        final value = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (value != null) setState(() => dueDate = value);
                      },
                      icon: const Icon(Icons.calendar_month),
                    ),
                  ],
                ),
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
        FilledButton(
          onPressed: () async {
            if (title.text.trim().isEmpty) return;
            final sameStatus = widget.store
                .records(EntityTypes.kanbanTask)
                .where((item) => item.payload['status'] == status);
            await widget.store.save(
              EntityTypes.kanbanTask,
              <String, dynamic>{
                ...?widget.entity?.payload,
                'title': title.text.trim(),
                'description': description.text.trim(),
                'status': status,
                'subjectId': subjectId,
                'contentId': contentId,
                'dueDate': dueDate == null
                    ? null
                    : DateFormat('yyyy-MM-dd').format(dueDate!),
                'order': widget.entity?.payload['order'] ?? sameStatus.length,
                'completedAt': status == 'done'
                    ? widget.entity?.payload['completedAt'] ??
                        DateTime.now().millisecondsSinceEpoch
                    : null,
                'createdAt': widget.entity?.payload['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              },
              id: widget.entity?.id,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _KanbanColumnInfo {
  const _KanbanColumnInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}
