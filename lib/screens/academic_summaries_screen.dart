import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/academic_data.dart';
import '../core/academic_folder_style.dart';
import '../core/academic_pdf_service.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/rich_summary_document.dart';
import '../core/summary_draft_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pro_color_picker.dart';
import '../widgets/study_folder_card.dart';
import '../widgets/summary_embed_widget.dart';
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
    final preferredSubjectId = entity?.payload['subjectId'] as String? ??
        subjectId ??
        widget.initialSubjectId;
    final scopedSubjectIds = AcademicData.subjectsForSelection(
      widget.store,
      preferredSubjectId: preferredSubjectId,
      courseMode:
          AcademicData.isCourseSubject(widget.store, preferredSubjectId),
    ).map((item) => item.id).toSet();
    final hasContent = widget.store
        .records(EntityTypes.studyContent)
        .any((item) => scopedSubjectIds.contains(item.payload['subjectId']));
    if (!hasContent) {
      _message(
        'Cadastre uma matéria ou módulo e um conteúdo primeiro.',
      );
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
    final preferredSubjectId = subjectId ?? widget.initialSubjectId;
    final courseMode =
        AcademicData.isCourseSubject(widget.store, preferredSubjectId);
    final semesters = courseMode
        ? AcademicData.sortedCourses(widget.store)
        : AcademicData.sortedSemesters(widget.store);
    final scopedSubjects = AcademicData.subjectsForSelection(
      widget.store,
      preferredSubjectId: preferredSubjectId,
      courseMode: courseMode,
    );
    final subjects = scopedSubjects.where((item) {
      return semesterId == null || item.payload['semesterId'] == semesterId;
    }).toList();
    final subjectIds = scopedSubjects.map((item) => item.id).toSet();
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
                      label: courseMode ? 'Curso' : 'Semestre',
                      value: semesterId,
                      allLabel:
                          courseMode ? 'Todos os cursos' : 'Todos os semestres',
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
                      label: courseMode ? 'Módulo' : 'Matéria',
                      value: subjectId,
                      allLabel:
                          courseMode ? 'Todos os módulos' : 'Todas as matérias',
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
          subtitle: 'Sempre ligados a uma matéria e a um conteúdo.',
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
          _SummaryFolderGrid(
            children: summaries
                .map(
                  (summary) => _SummaryCard(
                    store: widget.store,
                    summary: summary,
                    onEdit: () => _openEditor(summary),
                  ),
                )
                .toList(),
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
            AppColors.appSurface.withValues(alpha: .96),
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
    final subject = store.byId(summary.payload['subjectId'] as String? ?? '');
    final color = AcademicFolderStyle.colorFor(
      summary,
      fallback: subject == null
          ? AppColors.primary
          : AcademicFolderStyle.colorFor(subject),
    );
    final count = <String>[
      if (images.isNotEmpty) '${images.length} imagem(ns)',
      if (attachments.isNotEmpty) '${attachments.length} anexo(s)',
      if (images.isEmpty && attachments.isEmpty) 'texto e PDF',
    ].join(' • ');
    return StudyFolderCard(
      title: summary.payload['title'] as String? ?? 'Resumo',
      subtitle: AcademicData.contentName(
        store,
        summary.payload['contentId'] as String?,
      ),
      countLabel: count,
      color: color,
      icon: AcademicFolderStyle.iconFor(summary),
      artIcon: Icons.auto_stories_rounded,
      coverBytes: AcademicFolderStyle.coverBytes(summary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AcademicSummaryDetailScreen(store: store, summaryId: summary.id),
        ),
      ),
      menuItems: const <StudyFolderMenuItem>[
        StudyFolderMenuItem(
          value: 'edit',
          label: 'Editar e personalizar',
          icon: Icons.edit_outlined,
        ),
        StudyFolderMenuItem(
          value: 'pdf',
          label: 'Gerar PDF',
          icon: Icons.picture_as_pdf_outlined,
        ),
        StudyFolderMenuItem(
          value: 'delete',
          label: 'Mover para a lixeira',
          icon: Icons.delete_outline,
          danger: true,
        ),
      ],
      onMenuSelected: (value) => _handleAction(context, value),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    if (value == 'edit') {
      onEdit();
      return;
    }
    if (value == 'pdf') {
      final path = await AcademicPdfService.exportSummary(
        store: store,
        summary: summary,
      );
      if (context.mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF salvo com sucesso.')));
      }
      return;
    }
    if (value != 'delete') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mover resumo para a lixeira?'),
        content: const Text(
          'O texto, as imagens e os anexos poderão ser restaurados pela Lixeira.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mover para a lixeira'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.remove(summary.id);
  }
}

class _SummaryFolderGrid extends StatelessWidget {
  const _SummaryFolderGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 380
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: constraints.maxWidth < 470 ? .75 : 1.08,
          children: children,
        );
      },
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
  static const String _toolbarPreferenceKey = 'summary_editor_toolbar_expanded';

  late final TextEditingController title;
  late final RichSummaryController body;
  late final FocusNode editorFocus;
  late final UndoHistoryController undoHistory;
  late final ScrollController editorScroll;
  late final SummaryDraftService draftService;
  late String? subjectId;
  late String? contentId;
  late List<Map<String, dynamic>> images;
  late List<Map<String, dynamic>> attachments;
  late int folderColor;
  late String folderIcon;
  late String coverImageBase64;
  late String coverImageName;
  final ValueNotifier<String> draftStatus = ValueNotifier<String>('');
  Timer? draftDebounce;
  bool pickingImages = false;
  bool pickingAttachments = false;
  bool saved = false;
  bool draftPersisted = false;
  bool sidePanelsVisible = true;
  bool editorToolbarExpanded = false;
  bool metadataExpanded = true;
  bool assetsExpanded = false;
  bool appearanceExpanded = false;
  bool pickingCover = false;

  @override
  void initState() {
    super.initState();
    final preferredSubject = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    final subjects = AcademicData.subjectsForSelection(
      widget.store,
      preferredSubjectId: preferredSubject,
      courseMode: AcademicData.isCourseSubject(widget.store, preferredSubject),
    );
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    body = RichSummaryController(
      widget.entity == null
          ? const RichSummaryDocument(text: '')
          : AcademicData.summaryDocument(widget.entity!),
    );
    editorFocus = FocusNode(debugLabel: 'summary-rich-editor');
    undoHistory = UndoHistoryController();
    editorScroll = ScrollController(debugLabel: 'summary-editor-scroll');
    draftService = SummaryDraftService(widget.store);
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
    final subject = subjectId == null ? null : widget.store.byId(subjectId!);
    folderColor = (widget.entity?.payload['folderColor'] as num?)?.toInt() ??
        (subject == null
            ? AppColors.primary.toARGB32()
            : AcademicFolderStyle.colorFor(subject).toARGB32());
    folderIcon = widget.entity?.payload['folderIcon'] as String? ?? 'notes';
    coverImageBase64 =
        widget.entity?.payload['coverImageBase64'] as String? ?? '';
    coverImageName = widget.entity?.payload['coverImageName'] as String? ?? '';
    title.addListener(_scheduleDraft);
    body.addListener(_scheduleDraft);
    unawaited(_loadToolbarPreference());
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  Future<void> _loadToolbarPreference() async {
    final saved = await widget.store.readUserPreference(_toolbarPreferenceKey);
    if (!mounted || saved == null) return;
    setState(() => editorToolbarExpanded = saved == 'true');
  }

  void _toggleEditorToolbar() {
    setState(() => editorToolbarExpanded = !editorToolbarExpanded);
    unawaited(
      widget.store.writeUserPreference(
        _toolbarPreferenceKey,
        editorToolbarExpanded.toString(),
      ),
    );
  }

  @override
  void dispose() {
    draftDebounce?.cancel();
    if (!saved && !draftPersisted) unawaited(_saveDraftNow());
    title.removeListener(_scheduleDraft);
    body.removeListener(_scheduleDraft);
    draftStatus.dispose();
    undoHistory.dispose();
    editorScroll.dispose();
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
    final subjects = AcademicData.subjectsForSelection(
      widget.store,
      preferredSubjectId: draft.subjectId ?? subjectId,
      courseMode: AcademicData.isCourseSubject(
        widget.store,
        draft.subjectId ?? subjectId,
      ),
    );
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
      if (draft.folderColor != null) folderColor = draft.folderColor!;
      folderIcon = draft.folderIcon;
      coverImageBase64 = draft.coverImageBase64;
      coverImageName = draft.coverImageName;
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
      body: body.plainText,
      richText: body.document.toJson(),
      subjectId: subjectId,
      contentId: contentId,
      images: images.map((item) => Map<String, dynamic>.from(item)).toList(),
      attachments:
          attachments.map((item) => Map<String, dynamic>.from(item)).toList(),
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      sourceUpdatedAtMs: widget.entity?.updatedAtMs ?? 0,
      folderColor: folderColor,
      folderIcon: folderIcon,
      coverImageBase64: coverImageBase64,
      coverImageName: coverImageName,
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

  Future<void> _insertInlineImage() async {
    try {
      final picked = await FileTransferService.pickImagePayload();
      final bytes = picked?['imageBytes'];
      if (!mounted || picked == null || bytes is! List<int>) return;
      final initial = SummaryEmbed(
        id: 'image-${DateTime.now().microsecondsSinceEpoch}',
        type: SummaryEmbed.imageType,
        name: picked['imageName'] as String? ?? 'imagem.jpg',
        base64: base64Encode(bytes),
        height: 280,
      );
      final configured = await showDialog<SummaryEmbed>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SummaryEmbedEditorDialog(embed: initial),
      );
      if (configured == null || !mounted) return;
      body.insertEmbed(configured);
      editorFocus.requestFocus();
      _scheduleDraft();
    } catch (error) {
      _showError('Não foi possível inserir a imagem: $error');
    }
  }

  Future<void> _insertCodeExample() async {
    final initial = SummaryEmbed(
      id: 'code-${DateTime.now().microsecondsSinceEpoch}',
      type: SummaryEmbed.codeType,
      language: 'dart',
      height: 250,
    );
    final configured = await showDialog<SummaryEmbed>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SummaryEmbedEditorDialog(embed: initial),
    );
    if (configured == null || !mounted) return;
    body.insertEmbed(configured);
    editorFocus.requestFocus();
    _scheduleDraft();
  }

  Future<void> _editEmbed(SummaryEmbed embed) async {
    final configured = await showDialog<SummaryEmbed>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SummaryEmbedEditorDialog(embed: embed),
    );
    if (configured == null || !mounted) return;
    body.updateEmbed(configured);
    _scheduleDraft();
  }

  void _removeEmbed(SummaryEmbed embed) {
    body.removeEmbed(embed.id);
    _scheduleDraft();
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

  Future<void> _pickCover() async {
    if (pickingCover) return;
    setState(() => pickingCover = true);
    try {
      final picked = await FileTransferService.pickImagePayload();
      final bytes = picked?['imageBytes'];
      if (picked != null && bytes is List<int> && mounted) {
        setState(() {
          coverImageBase64 = base64Encode(bytes);
          coverImageName = picked['imageName'] as String? ?? 'capa.jpg';
        });
        _scheduleDraft();
      }
    } catch (error) {
      _showError('Não foi possível usar a capa: $error');
    } finally {
      if (mounted) setState(() => pickingCover = false);
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
      _showError('Escolha uma matéria e um conteúdo.');
      return;
    }
    final previous = widget.entity?.payload ?? const <String, dynamic>{};
    await widget.store.save(
        EntityTypes.studyNote,
        <String, dynamic>{
          ...previous,
          'title': title.text.trim(),
          'body': body.plainText,
          'richText': body.document.toJson(),
          'subjectId': subjectId,
          'contentId': contentId,
          'images': images,
          'attachments': attachments,
          'folderColor': folderColor,
          'folderIcon': folderIcon,
          'coverImageBase64': coverImageBase64,
          'coverImageName': coverImageName,
          'createdAt':
              previous['createdAt'] ?? DateTime.now().toIso8601String(),
          'editedAt': DateTime.now().toIso8601String(),
        },
        id: widget.entity?.id);
    saved = true;
    draftDebounce?.cancel();
    await draftService.clear(widget.entity?.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preferredSubject = subjectId ??
        widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    final courseMode =
        AcademicData.isCourseSubject(widget.store, preferredSubject);
    final subjects = AcademicData.subjectsForSelection(
      widget.store,
      preferredSubjectId: preferredSubject,
      courseMode: courseMode,
    );
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
              IconButton(
                key: const Key('summary-toggle-side-panels'),
                tooltip: sidePanelsVisible
                    ? 'Ocultar organização e materiais'
                    : 'Mostrar organização e materiais',
                onPressed: () =>
                    setState(() => sidePanelsVisible = !sidePanelsVisible),
                icon: Icon(
                  sidePanelsVisible
                      ? Icons.fullscreen_rounded
                      : Icons.view_sidebar_outlined,
                ),
              ),
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
                  courseMode: courseMode,
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
                  expanded: metadataExpanded,
                  onToggle: () =>
                      setState(() => metadataExpanded = !metadataExpanded),
                );
                final editor = _SummaryEditorCanvas(
                  controller: body,
                  focusNode: editorFocus,
                  undoController: undoHistory,
                  scrollController: editorScroll,
                  onInsertInlineImage: _insertInlineImage,
                  onInsertCode: _insertCodeExample,
                  onEditEmbed: _editEmbed,
                  onDeleteEmbed: _removeEmbed,
                  toolbarExpanded: editorToolbarExpanded,
                  onToggleToolbar: _toggleEditorToolbar,
                  panelsVisible: sidePanelsVisible,
                  onTogglePanels: desktop
                      ? () => setState(
                            () => sidePanelsVisible = !sidePanelsVisible,
                          )
                      : null,
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
                  expanded: assetsExpanded,
                  onToggle: () =>
                      setState(() => assetsExpanded = !assetsExpanded),
                );
                final appearance = _SummaryAppearancePanel(
                  color: Color(folderColor),
                  iconId: folderIcon,
                  coverName: coverImageName,
                  pickingCover: pickingCover,
                  expanded: appearanceExpanded,
                  onToggle: () =>
                      setState(() => appearanceExpanded = !appearanceExpanded),
                  onColorChanged: (value) {
                    setState(() => folderColor = value.toARGB32());
                    _scheduleDraft();
                  },
                  onIconChanged: (value) {
                    setState(() => folderIcon = value);
                    _scheduleDraft();
                  },
                  onPickCover: _pickCover,
                  onRemoveCover: () {
                    setState(() {
                      coverImageBase64 = '';
                      coverImageName = '';
                    });
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
                            if (sidePanelsVisible) ...<Widget>[
                              const SizedBox(width: 12),
                              SizedBox(
                                key: const Key('summary-side-panels'),
                                width: 288,
                                child: ListView(
                                  children: <Widget>[
                                    metadata,
                                    const SizedBox(height: 10),
                                    appearance,
                                    const SizedBox(height: 10),
                                    assets,
                                  ],
                                ),
                              ),
                            ],
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
                    appearance,
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
    required this.courseMode,
    required this.onSubjectChanged,
    required this.onContentChanged,
    required this.expanded,
    required this.onToggle,
  });

  final TextEditingController title;
  final List<SyncEntity> subjects;
  final List<SyncEntity> contents;
  final String? subjectId;
  final String? contentId;
  final bool courseMode;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onContentChanged;
  final bool expanded;
  final VoidCallback onToggle;

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
              IconButton(
                key: const Key('summary-toggle-metadata'),
                tooltip:
                    expanded ? 'Recolher organização' : 'Abrir organização',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ),
            ],
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('summary-title-field'),
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Título do resumo',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey<String?>('summary-subject-$subjectId'),
              initialValue: subjects.any((item) => item.id == subjectId)
                  ? subjectId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: courseMode ? 'Módulo do curso' : 'Matéria',
              ),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey<String?>('summary-content-$contentId'),
              initialValue: contents.any((item) => item.id == contentId)
                  ? contentId
                  : null,
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
              Text(
                courseMode
                    ? 'Cadastre um conteúdo nesse módulo antes de salvar.'
                    : 'Cadastre um conteúdo nessa matéria antes de salvar.',
                style: TextStyle(color: AppColors.orange, fontSize: 12),
              ),
            ],
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
    required this.undoController,
    required this.scrollController,
    required this.onInsertInlineImage,
    required this.onInsertCode,
    required this.onEditEmbed,
    required this.onDeleteEmbed,
    required this.toolbarExpanded,
    required this.onToggleToolbar,
    required this.panelsVisible,
    this.onTogglePanels,
  });

  final RichSummaryController controller;
  final FocusNode focusNode;
  final UndoHistoryController undoController;
  final ScrollController scrollController;
  final VoidCallback onInsertInlineImage;
  final VoidCallback onInsertCode;
  final ValueChanged<SummaryEmbed> onEditEmbed;
  final ValueChanged<SummaryEmbed> onDeleteEmbed;
  final bool toolbarExpanded;
  final VoidCallback onToggleToolbar;
  final bool panelsVisible;
  final VoidCallback? onTogglePanels;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('summary-editor-canvas'),
      decoration: BoxDecoration(
        color: AppColors.appSurface.withValues(alpha: .98),
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
              color: AppColors.appSurfaceRaised.withValues(alpha: .95),
              border: Border(bottom: BorderSide(color: AppColors.appBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton.icon(
                        key: const Key('summary-toggle-toolbar'),
                        onPressed: onToggleToolbar,
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5,
                          ),
                          foregroundColor: toolbarExpanded
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                        ),
                        icon: Icon(
                          toolbarExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                        label: Text(
                          toolbarExpanded
                              ? 'RECOLHER FERRAMENTAS'
                              : 'ABRIR FERRAMENTAS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: .35),
                        ),
                      ),
                      child: Text(
                        'PÁGINA A4',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    if (onTogglePanels != null) ...<Widget>[
                      const SizedBox(width: 5),
                      IconButton(
                        key: const Key('summary-focus-mode'),
                        tooltip: panelsVisible
                            ? 'Modo foco: ocultar painéis'
                            : 'Mostrar organização e materiais',
                        visualDensity: VisualDensity.compact,
                        onPressed: onTogglePanels,
                        icon: Icon(
                          panelsVisible
                              ? Icons.center_focus_strong_outlined
                              : Icons.view_sidebar_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: toolbarExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: _RichTextToolbar(
                            key: const Key('summary-editor-toolbar'),
                            controller: controller,
                            focusNode: focusNode,
                            undoController: undoController,
                            onInsertInlineImage: onInsertInlineImage,
                            onInsertCode: onInsertCode,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              key: const Key('summary-a4-workspace'),
              color: const Color(0xFF030D19),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final outerMargin = compact ? 8.0 : 22.0;
                  final availableWidth = constraints.maxWidth - outerMargin * 2;
                  final pageWidth = availableWidth > 820
                      ? 820.0
                      : availableWidth.clamp(1.0, 820.0).toDouble();
                  final pageHeight = (constraints.maxHeight - 24)
                      .clamp(1.0, constraints.maxHeight)
                      .toDouble();
                  final horizontalMargin = compact ? 22.0 : 52.0;
                  final verticalMargin = compact ? 28.0 : 46.0;
                  final contentWidth = (pageWidth - horizontalMargin * 2).clamp(
                    120,
                    716,
                  );
                  controller.setEmbedBuilder(
                    (embed) => SummaryEmbedWidget(
                      key: ValueKey<String>('summary-embed-${embed.id}'),
                      embed: embed,
                      maxWidth: contentWidth.toDouble(),
                      editable: true,
                      onEdit: () => onEditEmbed(embed),
                      onDelete: () => onDeleteEmbed(embed),
                    ),
                  );
                  return Center(
                    child: SizedBox(
                      key: const Key('summary-a4-page'),
                      width: pageWidth,
                      height: pageHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1D32),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .6),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .48),
                              blurRadius: 34,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Scrollbar(
                            controller: scrollController,
                            thumbVisibility: !compact,
                            child: AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) => CallbackShortcuts(
                                bindings: <ShortcutActivator, VoidCallback>{
                                  const SingleActivator(
                                    LogicalKeyboardKey.keyB,
                                    control: true,
                                  ): () => controller.applyToSelection(
                                        (style) =>
                                            style.copyWith(bold: !style.bold),
                                      ),
                                  const SingleActivator(
                                    LogicalKeyboardKey.keyI,
                                    control: true,
                                  ): () => controller.applyToSelection(
                                        (style) => style.copyWith(
                                            italic: !style.italic),
                                      ),
                                  const SingleActivator(
                                    LogicalKeyboardKey.keyU,
                                    control: true,
                                  ): () => controller.applyToSelection(
                                        (style) => style.copyWith(
                                          underline: !style.underline,
                                        ),
                                      ),
                                  const SingleActivator(
                                    LogicalKeyboardKey.keyK,
                                    control: true,
                                    shift: true,
                                  ): controller.toggleCodeBlock,
                                  const SingleActivator(
                                    LogicalKeyboardKey.f1,
                                    control: true,
                                  ): onToggleToolbar,
                                  const SingleActivator(
                                    LogicalKeyboardKey.tab,
                                  ): () => controller.indentParagraphs(
                                        outdent: false,
                                      ),
                                  const SingleActivator(
                                    LogicalKeyboardKey.tab,
                                    shift: true,
                                  ): () => controller.indentParagraphs(
                                        outdent: true,
                                      ),
                                },
                                child: TextField(
                                  key: const ValueKey<String>(
                                    'summary-body-field',
                                  ),
                                  controller: controller,
                                  focusNode: focusNode,
                                  undoController: undoController,
                                  scrollController: scrollController,
                                  expands: true,
                                  minLines: null,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textAlign: controller.flutterTextAlign,
                                  textAlignVertical: TextAlignVertical.top,
                                  strutStyle: StrutStyle(
                                    fontSize: 16,
                                    height: controller.lineHeight,
                                    forceStrutHeight: false,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: controller.lineHeight,
                                    decoration: TextDecoration.none,
                                  ),
                                  cursorColor: AppColors.primaryLight,
                                  scrollPadding: const EdgeInsets.all(88),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Comece pelo conceito principal. Use títulos, listas, destaques, exemplos e observações…',
                                    hintStyle: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 16,
                                      height: controller.lineHeight,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.fromLTRB(
                                      horizontalMargin,
                                      verticalMargin,
                                      horizontalMargin,
                                      verticalMargin + 42,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: AppColors.appSurfaceRaised.withValues(alpha: .8),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: <Widget>[
                  Icon(Icons.lock_outline, size: 15, color: AppColors.green),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Rascunho local automático • nada vai para a nuvem',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) {
                      final trimmed = controller.plainText.trim();
                      final words = trimmed.isEmpty
                          ? 0
                          : trimmed.split(RegExp(r'\s+')).length;
                      final readingMinutes =
                          words == 0 ? 0 : (words / 220).ceil();
                      return Text(
                        constraints.maxWidth < 660
                            ? '$words palavras'
                            : '$words palavras • ${controller.plainText.length} caracteres • $readingMinutes min',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
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
    );
  }
}

class _RichTextToolbar extends StatelessWidget {
  const _RichTextToolbar({
    required this.controller,
    required this.focusNode,
    required this.undoController,
    required this.onInsertInlineImage,
    required this.onInsertCode,
    super.key,
  });

  final RichSummaryController controller;
  final FocusNode focusNode;
  final UndoHistoryController undoController;
  final VoidCallback onInsertInlineImage;
  final VoidCallback onInsertCode;

  void _run(VoidCallback action) {
    action();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[controller, undoController]),
      builder: (context, _) {
        final style = controller.activeStyle;
        final tools = <Widget>[
          _FormatButton(
            tooltip: 'Desfazer (Ctrl+Z)',
            icon: Icons.undo_rounded,
            onPressed: undoController.value.canUndo
                ? () => _run(undoController.undo)
                : null,
          ),
          _FormatButton(
            tooltip: 'Refazer (Ctrl+Y)',
            icon: Icons.redo_rounded,
            onPressed: undoController.value.canRedo
                ? () => _run(undoController.redo)
                : null,
          ),
          const _ToolbarDivider(),
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
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.appBorder),
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
                (current) => current.copyWith(fontSize: current.fontSize - 2),
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
                (current) => current.copyWith(fontSize: current.fontSize + 2),
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
                (current) => current.copyWith(underline: !current.underline),
              ),
            ),
          ),
          _FormatButton(
            tooltip: 'Tachado',
            icon: Icons.format_strikethrough,
            selected: style.strikeThrough,
            onPressed: () => _run(
              () => controller.applyToSelection(
                (current) =>
                    current.copyWith(strikeThrough: !current.strikeThrough),
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
            tooltip: 'Marca-texto',
            icon: Icons.format_color_fill_rounded,
            selected: style.highlight,
            onPressed: () => _run(
              () => controller.applyToSelection(
                (current) => current.copyWith(highlight: !current.highlight),
              ),
            ),
          ),
          _FormatButton(
            tooltip: 'Código em linha',
            icon: Icons.data_object_rounded,
            selected: style.monospace,
            onPressed: () => _run(
              () => controller.applyToSelection(
                (current) => current.copyWith(monospace: !current.monospace),
              ),
            ),
          ),
          _FormatButton(
            tooltip: 'Bloco de código (Ctrl+Shift+K)',
            icon: Icons.terminal_rounded,
            selected: style.codeBlock,
            onPressed: () => _run(controller.toggleCodeBlock),
          ),
          _FormatButton(
            tooltip: 'Inserir imagem dentro do texto',
            icon: Icons.add_photo_alternate_outlined,
            onPressed: onInsertInlineImage,
          ),
          _FormatButton(
            tooltip: 'Inserir caixa profissional de código',
            icon: Icons.integration_instructions_outlined,
            onPressed: onInsertCode,
          ),
          const _ToolbarDivider(),
          PopupMenuButton<String>(
            tooltip: 'Alinhamento do documento',
            onSelected: (value) =>
                _run(() => controller.setTextAlignment(value)),
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'left', child: Text('Alinhar à esquerda')),
              PopupMenuItem(value: 'center', child: Text('Centralizar')),
              PopupMenuItem(value: 'right', child: Text('Alinhar à direita')),
              PopupMenuItem(value: 'justify', child: Text('Justificar texto')),
            ],
            child: _ToolbarMenuButton(
              tooltip: 'Alinhamento',
              icon: switch (controller.textAlignment) {
                'center' => Icons.format_align_center_rounded,
                'right' => Icons.format_align_right_rounded,
                'justify' => Icons.format_align_justify_rounded,
                _ => Icons.format_align_left_rounded,
              },
              label: 'Alinhar',
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<double>(
            tooltip: 'Espaçamento entre linhas',
            onSelected: (value) => _run(() => controller.setLineHeight(value)),
            itemBuilder: (_) => const <PopupMenuEntry<double>>[
              PopupMenuItem(value: 1.15, child: Text('Compacto — 1,15')),
              PopupMenuItem(value: 1.35, child: Text('Confortável — 1,35')),
              PopupMenuItem(value: 1.55, child: Text('Padrão — 1,55')),
              PopupMenuItem(value: 1.8, child: Text('Amplo — 1,80')),
              PopupMenuItem(value: 2.0, child: Text('Duplo — 2,00')),
            ],
            child: _ToolbarMenuButton(
              tooltip: 'Entrelinhas',
              icon: Icons.format_line_spacing_rounded,
              label: controller.lineHeight.toStringAsFixed(2),
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
            tooltip: 'Lista de tarefas',
            icon: Icons.check_box_outlined,
            onPressed: () => _run(controller.replaceParagraphsWithChecklist),
          ),
          _FormatButton(
            tooltip: 'Citação',
            icon: Icons.format_quote_rounded,
            onPressed: () => _run(controller.replaceParagraphsWithQuote),
          ),
          _FormatButton(
            tooltip: 'Diminuir recuo',
            icon: Icons.format_indent_decrease_rounded,
            onPressed: () =>
                _run(() => controller.indentParagraphs(outdent: true)),
          ),
          _FormatButton(
            tooltip: 'Aumentar recuo',
            icon: Icons.format_indent_increase_rounded,
            onPressed: () =>
                _run(() => controller.indentParagraphs(outdent: false)),
          ),
          _FormatButton(
            tooltip: 'Inserir linha divisória',
            icon: Icons.horizontal_rule_rounded,
            onPressed: () => _run(controller.insertDivider),
          ),
          const _ToolbarDivider(),
          _FormatButton(
            tooltip: 'Selecionar todo o texto',
            icon: Icons.select_all_rounded,
            onPressed: () => _run(controller.selectAllText),
          ),
          _FormatButton(
            tooltip: 'Limpar formatação',
            icon: Icons.format_clear,
            onPressed: () => _run(controller.clearFormatting),
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 880) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: tools),
              );
            }
            return Wrap(
              spacing: 1,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tools,
            );
          },
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
  final VoidCallback? onPressed;
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

class _ToolbarMenuButton extends StatelessWidget {
  const _ToolbarMenuButton({
    required this.tooltip,
    required this.icon,
    required this.label,
  });

  final String tooltip;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AppColors.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.appBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.primaryLight),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
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
      color: AppColors.appBorder,
    );
  }
}

class _SummaryEmbedEditorDialog extends StatefulWidget {
  const _SummaryEmbedEditorDialog({required this.embed});

  final SummaryEmbed embed;

  @override
  State<_SummaryEmbedEditorDialog> createState() =>
      _SummaryEmbedEditorDialogState();
}

class _SummaryEmbedEditorDialogState extends State<_SummaryEmbedEditorDialog> {
  late final TextEditingController content;
  late String language;
  late String alignment;
  late double widthFactor;
  late double height;

  @override
  void initState() {
    super.initState();
    content = TextEditingController(
      text: widget.embed.isCode ? widget.embed.code : widget.embed.caption,
    );
    language =
        SummaryCodeLanguage.all.any((item) => item.id == widget.embed.language)
            ? widget.embed.language
            : SummaryCodeLanguage.all.first.id;
    alignment = widget.embed.alignment;
    widthFactor = widget.embed.widthFactor;
    height = widget.embed.height;
  }

  @override
  void dispose() {
    content.dispose();
    super.dispose();
  }

  void _insertTab() {
    final value = content.value;
    final start =
        value.selection.isValid ? value.selection.start : value.text.length;
    final end =
        value.selection.isValid ? value.selection.end : value.text.length;
    const spaces = '  ';
    content.value = value.copyWith(
      text: value.text.replaceRange(start, end, spaces),
      selection: TextSelection.collapsed(offset: start + spaces.length),
      composing: TextRange.empty,
    );
  }

  void _save() {
    if (widget.embed.isCode && content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código de exemplo.')),
      );
      return;
    }
    Navigator.of(context).pop(
      widget.embed.copyWith(
        widthFactor: widthFactor,
        height: height,
        alignment: alignment,
        caption: widget.embed.isImage ? content.text.trim() : null,
        language: widget.embed.isCode ? language : null,
        code: widget.embed.isCode ? content.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCode = widget.embed.isCode;
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(
            isCode
                ? Icons.integration_instructions_outlined
                : Icons.image_outlined,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(isCode ? 'Caixa de código' : 'Imagem dentro do texto'),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isCode) ...<Widget>[
                DropdownButtonFormField<String>(
                  initialValue: language,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Linguagem exibida no cabeçalho',
                    prefixIcon: Icon(Icons.code_rounded),
                  ),
                  items: SummaryCodeLanguage.all
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => language = value);
                  },
                ),
                const SizedBox(height: 12),
                CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.tab): _insertTab,
                  },
                  child: TextField(
                    controller: content,
                    minLines: 8,
                    maxLines: 16,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontFamilyFallback: <String>[
                        'Cascadia Code',
                        'Courier New',
                        'monospace',
                      ],
                      fontSize: 13,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Código apenas para exemplo',
                      alignLabelWithHint: true,
                      helperText:
                          'Tab insere dois espaços. O código não será executado.',
                    ),
                  ),
                ),
              ] else ...<Widget>[
                TextField(
                  controller: content,
                  maxLength: 180,
                  decoration: const InputDecoration(
                    labelText: 'Legenda opcional',
                    prefixIcon: Icon(Icons.short_text_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Largura na folha: ${(widthFactor * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Slider(
                value: widthFactor,
                min: .3,
                max: 1,
                divisions: 14,
                label: '${(widthFactor * 100).round()}%',
                onChanged: (value) => setState(() => widthFactor = value),
              ),
              Text(
                'Altura: ${height.round()} px',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Slider(
                value: height.clamp(110, 560),
                min: 110,
                max: 560,
                divisions: 18,
                label: '${height.round()} px',
                onChanged: (value) => setState(() => height = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: alignment,
                decoration: const InputDecoration(
                  labelText: 'Posição na folha',
                  prefixIcon: Icon(Icons.format_align_center_rounded),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'left', child: Text('Esquerda')),
                  DropdownMenuItem(value: 'center', child: Text('Centro')),
                  DropdownMenuItem(value: 'right', child: Text('Direita')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => alignment = value);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'A largura e a altura ficam sempre limitadas à página A4.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Inserir'),
        ),
      ],
    );
  }
}

class _SummaryAppearancePanel extends StatelessWidget {
  const _SummaryAppearancePanel({
    required this.color,
    required this.iconId,
    required this.coverName,
    required this.pickingCover,
    required this.expanded,
    required this.onToggle,
    required this.onColorChanged,
    required this.onIconChanged,
    required this.onPickCover,
    required this.onRemoveCover,
  });

  final Color color;
  final String iconId;
  final String coverName;
  final bool pickingCover;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onIconChanged;
  final VoidCallback onPickCover;
  final VoidCallback onRemoveCover;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.palette_outlined, color: color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Aparência da pasta',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                key: const Key('summary-toggle-appearance'),
                tooltip: expanded ? 'Recolher aparência' : 'Abrir aparência',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ),
            ],
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 11),
            ProColorTile(
              title: 'Cor livre',
              subtitle: 'Paleta visual e código HEX',
              color: color,
              onChanged: onColorChanged,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: AcademicFolderStyle.icons
                  .map(
                    (option) => IconButton.filledTonal(
                      tooltip: option.label,
                      style: IconButton.styleFrom(
                        backgroundColor: iconId == option.id
                            ? color.withValues(alpha: .28)
                            : null,
                        side: iconId == option.id
                            ? BorderSide(color: color)
                            : null,
                      ),
                      onPressed: () => onIconChanged(option.id),
                      icon: Icon(option.icon, size: 19),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: pickingCover ? null : onPickCover,
              icon: pickingCover
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(coverName.isEmpty ? 'Adicionar capa' : 'Trocar capa'),
            ),
            if (coverName.isNotEmpty) ...<Widget>[
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      coverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover capa',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoveCover,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
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
    required this.expanded,
    required this.onToggle,
  });

  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> attachments;
  final bool pickingImages;
  final bool pickingAttachments;
  final VoidCallback onAddImages;
  final VoidCallback onAddAttachments;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onRemoveAttachment;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.collections_bookmark_outlined,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Materiais do resumo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                key: const Key('summary-toggle-assets'),
                tooltip: expanded ? 'Recolher materiais' : 'Abrir materiais',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ),
            ],
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 11),
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
                    color: AppColors.appSurfaceRaised.withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.appBorder),
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
              'Materiais fixados entram no backup e na sincronização Wi‑Fi, mas ficam somente no app e não entram no PDF.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
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
                            borderColor: AppColors.primary.withValues(
                              alpha: .48,
                            ),
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
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (context, constraints) => RichText(
                                      textAlign: document.flutterTextAlign,
                                      text: document.toTextSpan(
                                        baseStyle: TextStyle(
                                          color: Color(0xFFDCEBFA),
                                          fontSize: 16,
                                          height: document.lineHeight,
                                          decoration: TextDecoration.none,
                                        ),
                                        accentColor: AppColors.primaryLight,
                                        embedBuilder: (embed) =>
                                            SummaryEmbedWidget(
                                          embed: embed,
                                          maxWidth: constraints.maxWidth,
                                        ),
                                      ),
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
                                              child: Text(
                                                'Imagem indisponível',
                                              ),
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
                                            .saveAttachment(
                                          attachment,
                                        );
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
          color: AppColors.appSurfaceRaised,
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
