import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/academic_folder_style.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';

class AcademicScheduleCard extends StatelessWidget {
  const AcademicScheduleCard({
    required this.subject,
    required this.session,
    this.course,
    this.compact = false,
    this.trailing,
    super.key,
  });

  final SyncEntity? subject;
  final SyncEntity? course;
  final SyncEntity session;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final source = course ?? subject;
    final courseMode = course != null;
    final color = source == null
        ? AppColors.primary
        : AcademicFolderStyle.colorFor(source);
    final cover =
        source == null ? null : AcademicFolderStyle.coverBytes(source);
    final name = source?.payload['name'] as String? ??
        (courseMode ? 'Curso removido' : 'Matéria removida');
    final room = session.payload['room'] as String? ?? '';
    final start = session.payload['start'] as String? ?? '--:--';
    final end = session.payload['end'] as String? ?? '--:--';
    return Semantics(
      label: '$name, das $start às $end',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _ScheduleCover(
              cover: cover,
              color: color,
              courseMode: courseMode,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: cover == null
                      ? <Color>[
                          color.withValues(alpha: .34),
                          AppColors.appSurface.withValues(alpha: .98),
                        ]
                      : <Color>[
                          Colors.black.withValues(alpha: .18),
                          Colors.black.withValues(alpha: .9),
                        ],
                ),
                border: Border.all(color: color.withValues(alpha: .72)),
                borderRadius: BorderRadius.circular(compact ? 16 : 20),
              ),
            ),
            Positioned(
              left: compact ? 10 : 13,
              top: compact ? 9 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 9,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xDC06111E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: .72)),
                ),
                child: Text(
                  '$start–$end',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              right: trailing == null ? (compact ? 9 : 12) : 42,
              top: compact ? 9 : 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xDC06111E),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withValues(alpha: .58)),
                ),
                child: Text(
                  courseMode ? 'CURSO' : 'FACULDADE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Positioned(right: 4, top: 4, child: trailing!),
            Positioned(
              left: compact ? 11 : 14,
              right: compact ? 11 : 14,
              bottom: compact ? 10 : 13,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: compact ? 34 : 42,
                    height: compact ? 34 : 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: .7)),
                    ),
                    child: Icon(
                      source == null
                          ? (courseMode
                              ? Icons.workspace_premium_outlined
                              : Icons.school_outlined)
                          : AcademicFolderStyle.iconFor(source),
                      color: Colors.white,
                      size: compact ? 19 : 23,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 12 : 15,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          room.isEmpty ? 'Sala não informada' : room,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: compact ? 9 : 11,
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
    );
  }
}

class _ScheduleCover extends StatelessWidget {
  const _ScheduleCover({
    required this.cover,
    required this.color,
    required this.courseMode,
  });

  final Uint8List? cover;
  final Color color;
  final bool courseMode;

  @override
  Widget build(BuildContext context) {
    if (cover != null) {
      return Image.memory(
        cover!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: color),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: .46),
            const Color(0xFF06111E),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            courseMode ? Icons.workspace_premium_rounded : Icons.school_rounded,
            size: 58,
            color: color.withValues(alpha: .22),
          ),
        ),
      ),
    );
  }
}
