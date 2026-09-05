import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/academic_data.dart';
import '../core/academic_pdf_service.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/rich_summary_document.dart';
import '../core/summary_draft_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class AcademicSummariesScreen extends StatefulWidget {
  const AcademicSummariesScreen({
    required this.store,
    this.initialSubjectId,
    this.initialContentId,
    super.key,
  });

  final AppStore store;
  final String? initialSubjectId;
  final String? initialContentId;

  @override
  State<AcademicSummariesScreen> createState() =>
      _AcademicSummariesScreenState();
}

class _AcademicSummariesScreenState extends State<AcademicSummariesScreen> {
  final search = TextEditingController();
  String? semesterId;
  String? subjectId;
  String? contentId;

  @override
  void initState() {
    super.initState();
    subjectId = widget.initialSubjectId;
    contentId = widget.initialContentId;
    if (subjectId != null) {
      semesterId =
          widget.store.byId(subjectId!)?.payload['semesterId'] as String?;
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _openEditor([SyncEntity? entity]) async {
    final academicSubjectIds = AcademicData.academicSubjects(widget.store)
        .map((item) => item.id)
        .toSet();
    final hasAcademicContent = widget.store
        .records(EntityTypes.studyContent)
        .any((item) => academicSubjectIds.contains(item.payload['subjectId']));
    if (!hasAcademicContent) {
      _message(
          'Cadastre uma cadeira e um conteúdo na área acadêmica primeiro.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcademicSummaryEditorDialog(
          store: widget.store,
          entity: entity,
          initialSubjectId: subjectId,
          initialContentId: contentId,
        ),
      ),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final semesters = AcademicData.sortedSemesters(widget.store);
    final academicSubjects = AcademicData.academicSubjects(widget.store);
    final subjects = academicSubjects.where((item) {
      return semesterId == null || item.payload['semesterId'] == semesterId;
    }).toList();
    final subjectIds = academicSubjects.map((item) => item.id).toSet();
    final contents =
        widget.store.records(EntityTypes.studyContent).where((item) {
      final linkedSubject = item.payload['subjectId'] as String?;
      if (!subjectIds.contains(linkedSubject)) return false;
      return subjectId == null || linkedSubject == subjectId;
    }).toList()
          ..sort(
            (a, b) => (a.payload['title'] as String? ?? '').compareTo(
              b.payload['title'] as String? ?? '',
            ),
          );
    final term = search.text.trim().toLowerCase();
    final summaries = widget.store.records(EntityTypes.studyNote).where((item) {
      final itemSubjectId = item.payload['subjectId'] as String?;
      if (!subjectIds.contains(itemSubjectId)) return false;
      final subject = widget.store.byId(itemSubjectId ?? '');
      if (semesterId != null && subject?.payload['semesterId'] != semesterId) {
        return false;
      }
      if (subjectId != null && itemSubjectId != subjectId) return false;
      if (contentId != null && item.payload['contentId'] != contentId) {
        return false;
      }
      if (term.isEmpty) return true;
      final haystack = <String>[
        item.payload['title'] as String? ?? '',
        AcademicData.summaryPlainText(item),
        AcademicData.subjectName(widget.store, itemSubjectId),
        AcademicData.contentName(
          widget.store,
          item.payload['contentId'] as String?,
        ),
      ].join(' ').toLowerCase();
      return haystack.contains(term);
    }).toList();

    return AcademicPageBody(
      maxWidth: 1260,
      children: <Widget>[
        PageIntro(
          eyebrow: 'Ambiente de prioridade',
          title: 'Sua biblioteca de resumos',
          subtitle:
              'Escreva com foco, formate títulos e trechos importantes, reúna imagens e anexos e gere um PDF organizado quando precisar.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        _SummaryFocusBanner(onCreate: () => _openEditor()),
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LayoutBuilder(
                builder: (context, constraints) {
                  final field = TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Buscar em títulos e textos',
                      prefixIcon: Icon(Icons.search),
                    ),
                  );
                  if (constraints.maxWidth < 680) return field;
                  return Row(
                    children: <Widget>[
                      Expanded(child: field),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo resumo'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final filters = <Widget>[
                    _FilterBox(
                      label: 'Semestre',
                      value: semesterId,
                      allLabel: 'Todos os semestres',
                      items: semesters
                          .map(
                            (item) => _FilterItem(
                              id: item.id,
                              label: item.payload['name'] as String? ?? '',
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        semesterId = value;
                        subjectId = null;
                        contentId = null;
                      }),
                    ),
                    _FilterBox(
                      label: 'Cadeira',
                      value: subjectId,
                      allLabel: 'Todas as cadeiras',
                      items: subjects
                          .map(
                            (item) => _FilterItem(
                              id: item.id,
                              label: item.payload['name'] as String? ?? '',
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        subjectId = value;
                        contentId = null;
                      }),
                    ),
                    _FilterBox(
                      label: 'Conteúdo',
                      value: contentId,
                      allLabel: 'Todos os conteúdos',
                      items: contents
                          .map(
                            (item) => _FilterItem(
                              id: item.id,
                              label: item.payload['title'] as String? ?? '',
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => contentId = value),
                    ),
                  ];
                  if (constraints.maxWidth < 720) {
                    return Column(
                      children: filters
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: item,
                            ),
                          )
                          .toList(),
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: filters[0]),
                      const SizedBox(width: 10),
                      Expanded(child: filters[1]),
                      const SizedBox(width: 10),
                      Expanded(child: filters[2]),
                    ],
                  );
                },
              ),
              if (MediaQuery.sizeOf(context).width < 680) ...<Widget>[
                const SizedBox(height: 2),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo resumo'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        AcademicSectionTitle(
          title: summaries.length == 1
              ? '1 resumo'
              : '${summaries.length} resumos',
          subtitle: 'Sempre ligados a uma cadeira e a um conteúdo.',
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          const EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'Nenhum resumo encontrado',
            message:
                'Crie seu primeiro resumo ou ajuste os filtros da biblioteca.',
          )
        else
          ...summaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _SummaryCard(
                store: widget.store,
                summary: summary,
                onEdit: () => _openEditor(summary),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryFocusBanner extends StatelessWidget {
  const _SummaryFocusBanner({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: .26),
            AppColors.surface.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .55)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.edit_note_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tudo para a matéria que importa agora',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Editor em tela cheia, rascunho automático e materiais reunidos no mesmo lugar.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 700) ...<Widget>[
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.draw_outlined),
              label: const Text('Começar a escrever'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.id, required this.label});

  final String id;
  final String label;
}

class _FilterBox extends StatelessWidget {
  const _FilterBox({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String allLabel;
  final List<_FilterItem> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<String?>(
      key: ValueKey<String?>('$label-$safeValue-${items.length}'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
        ...items.map(
          (item) => DropdownMenuItem<String?>(
            value: item.id,
            child: Text(item.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.store,
    required this.summary,
    required this.onEdit,
  });

  final AppStore store;
  final SyncEntity summary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final images = AcademicData.summaryImages(summary);
    final attachments = AcademicData.summaryAttachments(summary);
    final preview = AcademicData.summaryPlainText(summary)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return PremiumCard(
      borderColor: AppColors.primary.withValues(alpha: .35),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AcademicSummaryDetailScreen(store: store, summaryId: summary.id),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.description_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  summary.payload['title'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    AcademicBadge(
                      label: AcademicData.subjectName(
                        store,
                        summary.payload['subjectId'] as String?,
                      ),
                    ),
                    AcademicBadge(
                      label: AcademicData.contentName(
                        store,
                        summary.payload['contentId'] as String?,
                      ),
                      color: AppColors.cyan,
                    ),
                    if (images.isNotEmpty)
                      AcademicBadge(
                        label: '${images.length} imagem(ns)',
                        color: AppColors.green,
                        icon: Icons.image_outlined,
                      ),
                    if (attachments.isNotEmpty)
                      AcademicBadge(
                        label: '${attachments.length} anexo(s)',
                        color: AppColors.orange,
                        icon: Icons.attach_file,
                      ),
                  ],
                ),
                if (preview.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.45,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Ações do resumo',
            onSelected: (value) async {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'pdf') {
                final path = await AcademicPdfService.exportSummary(
                  store: store,
                  summary: summary,
                );
                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF salvo com sucesso.')),
                  );
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Excluir resumo?'),
                    content: const Text(
                      'O texto, as imagens e os anexos serão enviados para a lixeira e a exclusão será sincronizada.',
                    ),
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
                if (confirmed == true) await store.remove(summary.id);
              }
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Gerar PDF'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Mover para a lixeira'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AcademicSummaryEditorDialog extends StatefulWidget {
  const AcademicSummaryEditorDialog({
    required this.store,
    this.entity,
    this.initialSubjectId,
    this.initialContentId,
    super.key,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSubjectId;
  final String? initialContentId;

  @override
  State<AcademicSummaryEditorDialog> createState() =>
      _AcademicSummaryEditorDialogState();
}

class _AcademicSummaryEditorDialogState
    extends State<AcademicSummaryEditorDialog> {
  late final TextEditingController title;
  late final RichSummaryController body;
  late final FocusNode editorFocus;
  late final SummaryDraftService draftService;
  late String? subjectId;
  late String? contentId;
  late List<Map<String, dynamic>> images;
  late List<Map<String, dynamic>> attachments;
  final ValueNotifier<String> draftStatus = ValueNotifier<String>('');
  Timer? draftDebounce;
  bool pickingImages = false;
  bool pickingAttachments = false;
  bool saved = false;
  bool draftPersisted = false;

  @override
  void initState() {
    super.initState();
    final subjects = AcademicData.academicSubjects(widget.store);
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    body = RichSummaryController(
      widget.entity == null
          ? const RichSummaryDocument(text: '')
          : AcademicData.summaryDocument(widget.entity!),
    );
    editorFocus = FocusNode(debugLabel: 'summary-rich-editor');
    draftService = SummaryDraftService(widget.store);
    final preferredSubject = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    subjectId = subjects.any((item) => item.id == preferredSubject)
        ? preferredSubject
        : (subjects.isEmpty ? null : subjects.first.id);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final preferredContent = widget.entity?.payload['contentId'] as String? ??
        widget.initialContentId;
    contentId = contents.any((item) => item.id == preferredContent)
        ? preferredContent
        : (contents.isEmpty ? null : contents.first.id);
    images = widget.entity == null
        ? <Map<String, dynamic>>[]
        : AcademicData.summaryImages(widget.entity!)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    attachments = widget.entity == null
        ? <Map<String, dynamic>>[]
        : AcademicData.summaryAttachments(widget.entity!)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    title.addListener(_scheduleDraft);
    body.addListener(_scheduleDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    draftDebounce?.cancel();
    if (!saved && !draftPersisted) unawaited(_saveDraftNow());
    title.removeListener(_scheduleDraft);
    body.removeListener(_scheduleDraft);
    draftStatus.dispose();
    editorFocus.dispose();
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await draftService.load(widget.entity?.id);
    if (!mounted || draft == null || !draft.hasContent) return;
    if (widget.entity != null &&
        draft.savedAtMs <= widget.entity!.updatedAtMs) {
      await draftService.clear(widget.entity?.id);
      return;
    }
    final subjects = AcademicData.academicSubjects(widget.store);
    final restoredSubject = subjects.any((item) => item.id == draft.subjectId)
        ? draft.subjectId
        : subjectId;
    final contents = AcademicData.contentsForSubject(
      widget.store,
      restoredSubject,
    );
    final restoredContent = contents.any((item) => item.id == draft.contentId)
        ? draft.contentId
        : contentId;
    title.text = draft.title;
    final richDocument = draft.richText.isEmpty
        ? RichSummaryDocument(text: draft.body)
        : RichSummaryDocument.fromPayload(<String, dynamic>{
            'body': draft.body,
            'richText': draft.richText,
          });
    body.loadDocument(richDocument);
    setState(() {
      subjectId = restoredSubject;
      contentId = restoredContent;
      images =
          draft.images.map((item) => Map<String, dynamic>.from(item)).toList();
      attachments = draft.attachments
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    });
    draftStatus.value = 'Rascunho restaurado automaticamente';
    draftPersisted = true;
  }

  void _scheduleDraft() {
    if (saved) return;
    draftPersisted = false;
    draftDebounce?.cancel();
    draftStatus.value = 'Salvando rascunho…';
    draftDebounce = Timer(
      const Duration(milliseconds: 650),
      () => unawaited(_saveDraftNow()),
    );
  }

  Future<void> _saveDraftNow() async {
    if (saved) return;
    final draft = SummaryDraft(
      title: title.text,
      body: body.text,
      richText: body.document.toJson(),
      subjectId: subjectId,
      contentId: contentId,
      images: images.map((item) => Map<String, dynamic>.from(item)).toList(),
      attachments:
          attachments.map((item) => Map<String, dynamic>.from(item)).toList(),
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      sourceUpdatedAtMs: widget.entity?.updatedAtMs ?? 0,
    );
    if (draft.hasContent) {
      await draftService.save(widget.entity?.id, draft);
      draftPersisted = true;
      if (mounted) draftStatus.value = 'Rascunho salvo neste aparelho';
    } else {
      await draftService.clear(widget.entity?.id);
      draftPersisted = true;
      if (mounted) draftStatus.value = '';
    }
  }

  Future<void> _pickImages() async {
    if (images.length >= 12) return;
    setState(() => pickingImages = true);
    try {
      final picked = await FileTransferService.pickImagePayloads();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        images.addAll(
          picked.map(
            (item) => <String, dynamic>{
              'name': item['imageName'] as String,
              'base64': base64Encode(item['imageBytes'] as Uint8List),
            },
          ),
        );
        if (images.length > 12) images = images.take(12).toList();
      });
      _scheduleDraft();
    } catch (error) {
      _showError('Não foi possível anexar a imagem: $error');
    } finally {
      if (mounted) setState(() => pickingImages = false);
    }
  }

  Future<void> _pickAttachments() async {
    if (attachments.length >= 20) return;
    setState(() => pickingAttachments = true);
    try {
      final picked = await FileTransferService.pickAttachmentPayloads();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        attachments.addAll(picked);
        if (attachments.length > 20) {
          attachments = attachments.take(20).toList();
        }
      });
      _scheduleDraft();
    } catch (error) {
      _showError('Não foi possível anexar o arquivo: $error');
    } finally {
      if (mounted) setState(() => pickingAttachments = false);
    }
  }

  void _showError(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              .replaceFirst('FileSystemException: ', '')
              .replaceFirst('FormatException: ', ''),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) {
      _showError('Informe o título do resumo.');
      return;
    }
    if (subjectId == null || contentId == null) {
      _showError('Escolha uma cadeira e um conteúdo.');
      return;
    }
    final previous = widget.entity?.payload ?? const <String, dynamic>{};
    await widget.store.save(
      EntityTypes.studyNote,
      <String, dynamic>{
        ...previous,
        'title': title.text.trim(),
        'body': body.text,
        'richText': body.document.toJson(),
        'subjectId': subjectId,
        'contentId': contentId,
        'images': images,
        'attachments': attachments,
        'createdAt': previous['createdAt'] ?? DateTime.now().toIso8601String(),
        'editedAt': DateTime.now().toIso8601String(),
      },
      id: widget.entity?.id,
    );
    saved = true;
    draftDebounce?.cancel();
    await draftService.clear(widget.entity?.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(widget.store);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final compactAppBar = MediaQuery.sizeOf(context).width < 720;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !saved) unawaited(_saveDraftNow());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entity == null ? 'Novo resumo' : 'Editar resumo'),
          actions: <Widget>[
            if (!compactAppBar)
              ValueListenableBuilder<String>(
                valueListenable: draftStatus,
                builder: (_, status, __) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(right: compactAppBar ? 4 : 12),
              child: compactAppBar
                  ? IconButton(
                      tooltip: 'Salvar resumo',
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                    )
                  : FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar'),
                    ),
            ),
          ],
        ),
        body: PremiumBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 960;
                final metadata = _SummaryMetadataPanel(
                  title: title,
                  subjects: subjects,
                  contents: contents,
                  subjectId: subjectId,
                  contentId: contentId,
                  onSubjectChanged: (value) {
                    setState(() {
                      subjectId = value;
                      final available = AcademicData.contentsForSubject(
                        widget.store,
                        subjectId,
                      );
                      contentId = available.isEmpty ? null : available.first.id;
                    });
                    _scheduleDraft();
                  },
                  onContentChanged: (value) {
                    setState(() => contentId = value);
                    _scheduleDraft();
                  },
                );
                final editor = _SummaryEditorCanvas(
                  controller: body,
                  focusNode: editorFocus,
                );
                final assets = _SummaryAssetsPanel(
                  images: images,
                  attachments: attachments,
                  pickingImages: pickingImages,
                  pickingAttachments: pickingAttachments,
                  onAddImages: _pickImages,
                  onAddAttachments: _pickAttachments,
                  onRemoveImage: (index) {
                    setState(() => images.removeAt(index));
                    _scheduleDraft();
                  },
                  onRemoveAttachment: (index) {
                    setState(() => attachments.removeAt(index));
                    _scheduleDraft();
                  },
                );
                if (desktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1460),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(child: editor),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 340,
                              child: ListView(
                                children: <Widget>[
                                  metadata,
                                  const SizedBox(height: 12),
                                  assets,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
                  children: <Widget>[
                    metadata,
                    const SizedBox(height: 12),
                    SizedBox(height: 570, child: editor),
                    const SizedBox(height: 12),
                    assets,
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar resumo'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetadataPanel extends StatelessWidget {
  const _SummaryMetadataPanel({
    required this.title,
    required this.subjects,
    required this.contents,
    required this.subjectId,
    required this.contentId,
    required this.onSubjectChanged,
    required this.onContentChanged,
  });

  final TextEditingController title;
  final List<SyncEntity> subjects;
  final List<SyncEntity> contents;
  final String? subjectId;
  final String? contentId;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onContentChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.account_tree_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Organização do resumo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey<String>('summary-title-field'),
            controller: title,
            decoration: const InputDecoration(
              labelText: 'Título do resumo',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>('summary-subject-$subjectId'),
            initialValue:
                subjects.any((item) => item.id == subjectId) ? subjectId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cadeira'),
            items: subjects
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.payload['name'] as String? ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>('summary-content-$contentId'),
            initialValue:
                contents.any((item) => item.id == contentId) ? contentId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Conteúdo'),
            items: contents
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.payload['title'] as String? ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: contents.isEmpty ? null : onContentChanged,
          ),
          if (contents.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Cadastre um conteúdo nessa cadeira antes de salvar.',
              style: TextStyle(color: AppColors.orange, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryEditorCanvas extends StatelessWidget {
  const _SummaryEditorCanvas({
    required this.controller,
    required this.focusNode,
  });

  final RichSummaryController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: .48),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised.withValues(alpha: .95),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'EDITOR DO RESUMO',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                _RichTextToolbar(controller: controller, focusNode: focusNode),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: const Color(0xFF07182D),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  key: const ValueKey<String>('summary-body-field'),
                  controller: controller,
                  focusNode: focusNode,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.55,
                    decoration: TextDecoration.none,
                  ),
                  cursorColor: AppColors.primaryLight,
                  decoration: const InputDecoration.collapsed(
                    hintText:
                        'Comece pelo conceito principal. Use títulos, listas, destaques, exemplos e observações…',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: AppColors.surfaceRaised.withValues(alpha: .8),
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline, size: 15, color: AppColors.green),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Rascunho local automático • nada é enviado para a nuvem',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, __) => Text(
                    '${controller.text.trim().isEmpty ? 0 : controller.text.trim().split(RegExp(r'\s+')).length} palavras',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RichTextToolbar extends StatelessWidget {
  const _RichTextToolbar({required this.controller, required this.focusNode});

  final RichSummaryController controller;
  final FocusNode focusNode;

  void _run(VoidCallback action) {
    action();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final style = controller.activeStyle;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              PopupMenuButton<String>(
                tooltip: 'Estilo do parágrafo',
                onSelected: (value) => _run(() {
                  switch (value) {
                    case 'title':
                      controller.applyHeading(30, bold: true);
                      break;
                    case 'subtitle':
                      controller.applyHeading(23, bold: true);
                      break;
                    case 'heading':
                      controller.applyHeading(19, bold: true);
                      break;
                    default:
                      controller.applyHeading(16, bold: false);
                      break;
                  }
                }),
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(value: 'body', child: Text('Texto normal')),
                  PopupMenuItem(value: 'title', child: Text('Título grande')),
                  PopupMenuItem(value: 'subtitle', child: Text('Subtítulo')),
                  PopupMenuItem(value: 'heading', child: Text('Cabeçalho')),
                ],
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.text_fields, size: 19),
                      SizedBox(width: 7),
                      Text('Estilo'),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _FormatButton(
                tooltip: 'Diminuir fonte',
                icon: Icons.text_decrease,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(
                      fontSize: current.fontSize - 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 42,
                alignment: Alignment.center,
                child: Text(
                  '${style.fontSize.round()}',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Aumentar fonte',
                icon: Icons.text_increase,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(
                      fontSize: current.fontSize + 2,
                    ),
                  ),
                ),
              ),
              const _ToolbarDivider(),
              _FormatButton(
                tooltip: 'Negrito',
                icon: Icons.format_bold,
                selected: style.bold,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(bold: !current.bold),
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Itálico',
                icon: Icons.format_italic,
                selected: style.italic,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(italic: !current.italic),
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Sublinhado',
                icon: Icons.format_underlined,
                selected: style.underline,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(
                      underline: !current.underline,
                    ),
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Tachado',
                icon: Icons.format_strikethrough,
                selected: style.strikeThrough,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(
                      strikeThrough: !current.strikeThrough,
                    ),
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Cor de destaque do aplicativo',
                icon: Icons.format_color_text,
                selected: style.accent,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(accent: !current.accent),
                  ),
                ),
              ),
              _FormatButton(
                tooltip: 'Trecho de código',
                icon: Icons.code,
                selected: style.monospace,
                onPressed: () => _run(
                  () => controller.applyToSelection(
                    (current) => current.copyWith(
                      monospace: !current.monospace,
                    ),
                  ),
                ),
              ),
              const _ToolbarDivider(),
              _FormatButton(
                tooltip: 'Lista com marcadores',
                icon: Icons.format_list_bulleted,
                onPressed: () => _run(
                  () => controller.replaceParagraphsWithList(numbered: false),
                ),
              ),
              _FormatButton(
                tooltip: 'Lista numerada',
                icon: Icons.format_list_numbered,
                onPressed: () => _run(
                  () => controller.replaceParagraphsWithList(numbered: true),
                ),
              ),
              _FormatButton(
                tooltip: 'Limpar formatação',
                icon: Icons.format_clear,
                onPressed: () => _run(controller.clearFormatting),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primary.withValues(alpha: .22)
              : Colors.transparent,
          foregroundColor: selected ? AppColors.primaryLight : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 27,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: AppColors.border,
    );
  }
}

class _SummaryAssetsPanel extends StatelessWidget {
  const _SummaryAssetsPanel({
    required this.images,
    required this.attachments,
    required this.pickingImages,
    required this.pickingAttachments,
    required this.onAddImages,
    required this.onAddAttachments,
    required this.onRemoveImage,
    required this.onRemoveAttachment,
  });

  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> attachments;
  final bool pickingImages;
  final bool pickingAttachments;
  final VoidCallback onAddImages;
  final VoidCallback onAddAttachments;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.collections_bookmark_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Materiais do resumo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed:
                pickingImages || images.length >= 12 ? null : onAddImages,
            icon: pickingImages
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text('Imagens (${images.length}/12)'),
          ),
          if (images.isNotEmpty) ...<Widget>[
            const SizedBox(height: 9),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => SizedBox(
                  width: 108,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: _MemoryThumbnail(
                          base64: images[index]['base64'] as String? ?? '',
                          width: 108,
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remover imagem',
                          onPressed: () => onRemoveImage(index),
                          icon: const Icon(Icons.close, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: pickingAttachments || attachments.length >= 20
                ? null
                : onAddAttachments,
            icon: pickingAttachments
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            label: Text('Outros anexos (${attachments.length}/20)'),
          ),
          if (attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ...List<Widget>.generate(attachments.length, (index) {
              final attachment = attachments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _attachmentIcon(attachment['name'] as String? ?? ''),
                      color: AppColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            attachment['name'] as String? ?? 'Anexo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatBytes(
                              (attachment['sizeBytes'] as num? ?? 0).toInt(),
                            ),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover anexo',
                      onPressed: () => onRemoveAttachment(index),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 7),
          const Text(
            'Imagens e anexos entram no backup e na sincronização Wi‑Fi.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class AcademicSummaryDetailScreen extends StatelessWidget {
  const AcademicSummaryDetailScreen({
    required this.store,
    required this.summaryId,
    super.key,
  });

  final AppStore store;
  final String summaryId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final summary = store.byId(summaryId);
        if (summary == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resumo indisponível')),
            body: const Center(
              child: Text('Este resumo não está mais disponível.'),
            ),
          );
        }
        final document = AcademicData.summaryDocument(summary);
        final images = AcademicData.summaryImages(summary);
        final attachments = AcademicData.summaryAttachments(summary);
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(summary.payload['title'] as String? ?? 'Resumo'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Editar resumo',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AcademicSummaryEditorDialog(
                      store: store,
                      entity: summary,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Gerar PDF',
                onPressed: () async {
                  final path = await AcademicPdfService.exportSummary(
                    store: store,
                    summary: summary,
                  );
                  if (context.mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF salvo com sucesso.')),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          body: PremiumBackground(
            child: SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          PremiumCard(
                            padding: EdgeInsets.all(
                              MediaQuery.sizeOf(context).width < 600 ? 18 : 30,
                            ),
                            borderColor:
                                AppColors.primary.withValues(alpha: .48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  summary.payload['title'] as String? ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    AcademicBadge(
                                      label: AcademicData.subjectName(
                                        store,
                                        summary.payload['subjectId'] as String?,
                                      ),
                                    ),
                                    AcademicBadge(
                                      label: AcademicData.contentName(
                                        store,
                                        summary.payload['contentId'] as String?,
                                      ),
                                      color: AppColors.cyan,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 26),
                                if (document.text.trim().isEmpty)
                                  const Text(
                                    'Este resumo ainda não possui texto.',
                                    style:
                                        TextStyle(color: AppColors.textMuted),
                                  )
                                else
                                  RichText(
                                    text: document.toTextSpan(
                                      baseStyle: const TextStyle(
                                        color: Color(0xFFDCEBFA),
                                        fontSize: 16,
                                        height: 1.58,
                                        decoration: TextDecoration.none,
                                      ),
                                      accentColor: AppColors.primaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (images.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 16),
                            const AcademicSectionTitle(
                              title: 'Imagens do resumo',
                            ),
                            const SizedBox(height: 10),
                            ...images.map(
                              (image) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PremiumCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.memory(
                                          _decode(
                                            image['base64'] as String? ?? '',
                                          ),
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(
                                            height: 100,
                                            child: Center(
                                              child:
                                                  Text('Imagem indisponível'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        image['name'] as String? ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (attachments.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 16),
                            const AcademicSectionTitle(
                              title: 'Anexos',
                              subtitle:
                                  'Salve uma cópia para abrir no aparelho.',
                            ),
                            const SizedBox(height: 10),
                            PremiumCard(
                              child: Column(
                                children: attachments.map((attachment) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      _attachmentIcon(
                                        attachment['name'] as String? ?? '',
                                      ),
                                      color: AppColors.orange,
                                    ),
                                    title: Text(
                                      attachment['name'] as String? ?? 'Anexo',
                                    ),
                                    subtitle: Text(
                                      _formatBytes(
                                        (attachment['sizeBytes'] as num? ?? 0)
                                            .toInt(),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Salvar anexo',
                                      onPressed: () async {
                                        final path = await FileTransferService
                                            .saveAttachment(attachment);
                                        if (context.mounted && path != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Anexo salvo com sucesso.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.download_outlined),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar aos resumos'),
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
      },
    );
  }
}

class _MemoryThumbnail extends StatelessWidget {
  const _MemoryThumbnail({required this.base64, required this.width});

  final String base64;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.memory(
        _decode(base64),
        width: width,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          color: AppColors.surfaceRaised,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

IconData _attachmentIcon(String name) {
  final extension =
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' || 'odt' => Icons.article_outlined,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
    'ppt' || 'pptx' => Icons.slideshow_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'mp3' || 'wav' || 'm4a' => Icons.audio_file_outlined,
    'mp4' || 'mkv' || 'avi' => Icons.video_file_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return 'Tamanho não informado';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Uint8List _decode(String value) {
  try {
    return base64Decode(value);
  } catch (_) {
    return Uint8List(0);
  }
}
