import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/academic_data.dart';
import '../core/academic_pdf_service.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class AcademicSummariesScreen extends StatefulWidget {
  const AcademicSummariesScreen({required this.store, super.key});

  final AppStore store;

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
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _newSummary() {
    if (widget.store.records(EntityTypes.subject).isEmpty) {
      _message('Cadastre uma matéria na Organização acadêmica primeiro.');
      return;
    }
    if (widget.store.records(EntityTypes.studyContent).isEmpty) {
      _message('Cadastre ao menos um conteúdo dentro da matéria primeiro.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AcademicSummaryEditorDialog(store: widget.store),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final semesters = AcademicData.sortedSemesters(widget.store);
    final subjects = widget.store.records(EntityTypes.subject).where((item) {
      return semesterId == null || item.payload['semesterId'] == semesterId;
    }).toList()
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final contents =
        widget.store.records(EntityTypes.studyContent).where((item) {
      return subjectId == null || item.payload['subjectId'] == subjectId;
    }).toList()
          ..sort(
            (a, b) => (a.payload['title'] as String? ?? '').compareTo(
              b.payload['title'] as String? ?? '',
            ),
          );
    final term = search.text.trim().toLowerCase();
    final summaries = widget.store.records(EntityTypes.studyNote).where((item) {
      final itemSubjectId = item.payload['subjectId'] as String?;
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
        item.payload['body'] as String? ?? '',
        AcademicData.subjectName(widget.store, itemSubjectId),
        AcademicData.contentName(
          widget.store,
          item.payload['contentId'] as String?,
        ),
      ].join(' ').toLowerCase();
      return haystack.contains(term);
    }).toList();

    return AcademicPageBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Biblioteca acadêmica',
          title: 'Resumos por matéria e conteúdo',
          subtitle:
              'Centralize texto e imagens, encontre tudo por semestre e gere um PDF individual quando precisar estudar ou imprimir.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final field = TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar nos resumos',
                prefixIcon: Icon(Icons.search),
              ),
            );
            final button = ElevatedButton.icon(
              onPressed: _newSummary,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Novo resumo'),
            );
            return wide
                ? Row(
                    children: <Widget>[
                      Expanded(child: field),
                      const SizedBox(width: 12),
                      button,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      field,
                      const SizedBox(height: 10),
                      button,
                    ],
                  );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String?>(
                initialValue: semesterId,
                decoration: const InputDecoration(labelText: 'Semestre'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos os semestres'),
                  ),
                  ...semesters.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.payload['name'] as String? ?? ''),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  semesterId = value;
                  subjectId = null;
                  contentId = null;
                }),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas as matérias'),
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
            ),
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<String?>(
                initialValue: contentId,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos os conteúdos'),
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
            ),
          ],
        ),
        const SizedBox(height: 18),
        AcademicSectionTitle(
          title: '${summaries.length} resumo(s)',
          subtitle: 'Os PDFs são gerados no próprio aparelho.',
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          const EmptyState(
            icon: Icons.summarize_outlined,
            title: 'Nenhum resumo encontrado',
            message:
                'Crie o primeiro resumo ou ajuste os filtros de semestre, matéria e conteúdo.',
          )
        else
          ...summaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _SummaryCard(store: widget.store, summary: summary),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.store, required this.summary});

  final AppStore store;
  final SyncEntity summary;

  @override
  Widget build(BuildContext context) {
    final images = AcademicData.summaryImages(summary);
    return PremiumCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AcademicSummaryDetailScreen(store: store, summaryId: summary.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.payload['title'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
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
                          color: AppColors.blue,
                        ),
                        if (images.isNotEmpty)
                          AcademicBadge(
                            label: '${images.length} imagem(ns)',
                            color: AppColors.green,
                            icon: Icons.image_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações do resumo',
                onSelected: (value) async {
                  if (value == 'edit') {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => AcademicSummaryEditorDialog(
                        store: store,
                        entity: summary,
                      ),
                    );
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
                          'O texto e todas as imagens deste resumo serão removidos e a exclusão será sincronizada.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
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
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Gerar PDF'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: AppColors.red),
                      title: Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.payload['body'] as String? ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          if (images.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length.clamp(0, 5).toInt(),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _MemoryThumbnail(
                  base64: images[index]['base64'] as String? ?? '',
                  width: 116,
                ),
              ),
            ),
          ],
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
  late final TextEditingController body;
  late String? subjectId;
  late String? contentId;
  late List<Map<String, dynamic>> images;
  bool picking = false;

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    body = TextEditingController(
      text: widget.entity?.payload['body'] as String? ?? '',
    );
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
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (images.length >= 12) return;
    setState(() => picking = true);
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível anexar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject).toList()
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo resumo' : 'Editar resumo'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título do resumo',
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final subject = DropdownButtonFormField<String>(
                    initialValue: subjectId,
                    decoration: const InputDecoration(labelText: 'Matéria'),
                    items: subjects
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.payload['name'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      subjectId = value;
                      final available = AcademicData.contentsForSubject(
                        widget.store,
                        subjectId,
                      );
                      contentId = available.isEmpty ? null : available.first.id;
                    }),
                  );
                  final content = DropdownButtonFormField<String>(
                    initialValue: contentId,
                    decoration: const InputDecoration(labelText: 'Conteúdo'),
                    items: contents
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.payload['title'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => contentId = value),
                  );
                  if (constraints.maxWidth >= 600) {
                    return Row(
                      children: <Widget>[
                        Expanded(child: subject),
                        const SizedBox(width: 12),
                        Expanded(child: content),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      subject,
                      const SizedBox(height: 12),
                      content,
                    ],
                  );
                },
              ),
              if (contents.isEmpty) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'Essa matéria ainda não possui conteúdo. Cadastre-o em Organização acadêmica.',
                  style: TextStyle(color: AppColors.orange),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: body,
                minLines: 10,
                maxLines: 24,
                decoration: const InputDecoration(
                  labelText: 'Texto do resumo',
                  alignLabelWithHint: true,
                  hintText:
                      'Organize conceitos, exemplos, trechos de código e observações da aula…',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: picking ? null : _pickImages,
                      icon: picking
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        images.isEmpty
                            ? 'Adicionar imagens'
                            : 'Adicionar mais (${images.length}/12)',
                      ),
                    ),
                  ),
                ],
              ),
              if (images.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  height: 116,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    onReorderItem: (oldIndex, newIndex) => setState(() {
                      final item = images.removeAt(oldIndex);
                      images.insert(newIndex, item);
                    }),
                    itemBuilder: (_, index) => Container(
                      key: ValueKey<String>('${images[index]['name']}-$index'),
                      width: 132,
                      margin: const EdgeInsets.only(right: 9),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: _MemoryThumbnail(
                              base64: images[index]['base64'] as String? ?? '',
                              width: 132,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: IconButton.filled(
                              tooltip: 'Remover imagem',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => images.removeAt(index)),
                              icon: const Icon(Icons.close, size: 17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Arraste para ordenar. As imagens entram no PDF, backup e sincronização Wi‑Fi.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
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
            if (title.text.trim().isEmpty ||
                subjectId == null ||
                contentId == null) {
              return;
            }
            await widget.store.save(
                EntityTypes.studyNote,
                <String, dynamic>{
                  'title': title.text.trim(),
                  'body': body.text.trim(),
                  'subjectId': subjectId,
                  'contentId': contentId,
                  'images': images,
                  'createdAt': widget.entity?.payload['createdAt'] ??
                      DateTime.now().toIso8601String(),
                  'editedAt': DateTime.now().toIso8601String(),
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar resumo'),
        ),
      ],
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
          return const Scaffold(
            body: Center(child: Text('Este resumo não está mais disponível.')),
          );
        }
        final images = AcademicData.summaryImages(summary);
        return Scaffold(
          appBar: AppBar(
            title: Text(summary.payload['title'] as String? ?? 'Resumo'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Editar',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AcademicSummaryEditorDialog(
                    store: store,
                    entity: summary,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              summary.payload['title'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
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
                                  color: AppColors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              summary.payload['body'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.65,
                              ),
                            ),
                            ...images.map(
                              (image) => Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
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
                                    const SizedBox(height: 6),
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
                          ],
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

Uint8List _decode(String value) {
  try {
    return base64Decode(value);
  } catch (_) {
    return Uint8List(0);
  }
}
