import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/notification_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final reminders = store.records(EntityTypes.reminder)
          ..sort((a, b) => (a.payload['dateTime'] as String? ?? '')
              .compareTo(b.payload['dateTime'] as String? ?? ''));
        return Scaffold(
          appBar: AppBar(title: const Text('Lembretes')),
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
                          eyebrow: 'Rotina',
                          title: 'Lembretes locais',
                          subtitle:
                              'No Android, os lembretes podem aparecer como notificação. No Windows, continuam visíveis no painel do aplicativo.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ElevatedButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => _ReminderDialog(store: store),
                              ),
                              icon: const Icon(Icons.add_alert_outlined),
                              label: const Text('Novo lembrete'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final allowed = await NotificationService.instance.requestPermission();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      allowed
                                          ? 'Permissão de notificações pronta.'
                                          : 'Permissão de notificações não concedida.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_active_outlined),
                              label: const Text('Ativar notificações'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (reminders.isEmpty)
                          const EmptyState(
                            icon: Icons.notifications_none,
                            title: 'Nenhum lembrete',
                            message: 'Crie lembretes para provas, contas, treinos ou qualquer compromisso da rotina.',
                          )
                        else
                          ...reminders.map(
                            (item) {
                              final date = DateTime.tryParse(item.payload['dateTime'] as String? ?? '');
                              final past = date != null && date.isBefore(DateTime.now());
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: PremiumCard(
                                  borderColor: past ? AppColors.border : AppColors.green.withValues(alpha: .5),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      past ? Icons.notifications_paused_outlined : Icons.notifications_active_outlined,
                                      color: past ? AppColors.textMuted : AppColors.green,
                                    ),
                                    title: Text(item.payload['title'] as String? ?? ''),
                                    subtitle: Text(
                                      '${_formatDateTime(item.payload['dateTime'] as String?)}\n${item.payload['notes'] ?? ''}',
                                    ),
                                    isThreeLine: (item.payload['notes'] as String? ?? '').isNotEmpty,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          onPressed: () => showDialog<void>(
                                            context: context,
                                            builder: (_) => _ReminderDialog(store: store, entity: item),
                                          ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        ConfirmDeleteButton(
                                          onDelete: () async {
                                            await NotificationService.instance.cancelReminder(item.id);
                                            await store.remove(item.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late final TextEditingController title;
  late final TextEditingController notes;
  late DateTime dateTime;
  String category = 'Geral';
  bool enabled = true;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.entity?.payload['title'] as String? ?? '');
    notes = TextEditingController(text: widget.entity?.payload['notes'] as String? ?? '');
    dateTime = DateTime.tryParse(widget.entity?.payload['dateTime'] as String? ?? '') ??
        DateTime.now().add(const Duration(hours: 1));
    category = widget.entity?.payload['category'] as String? ?? 'Geral';
    enabled = widget.entity?.payload['enabled'] != false;
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await pickAppDate(context, dateTime);
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo lembrete' : 'Editar lembrete'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: const <String>['Geral', 'Estudos', 'Treinos', 'Finanças']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => category = value ?? category),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data e hora'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(dateTime)),
              trailing: const Icon(Icons.event_outlined),
              onTap: _pickDateTime,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrete ativo'),
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (title.text.trim().isEmpty) return;
            final entity = await widget.store.save(EntityTypes.reminder, <String, dynamic>{
              'title': title.text.trim(),
              'notes': notes.text.trim(),
              'category': category,
              'dateTime': dateTime.toIso8601String(),
              'enabled': enabled,
            }, id: widget.entity?.id);
            await NotificationService.instance.scheduleReminder(entity);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy HH:mm').format(date);
}
