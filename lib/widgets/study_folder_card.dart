import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class StudyFolderMenuItem {
  const StudyFolderMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.danger = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool danger;
}

class StudyFolderCard extends StatelessWidget {
  const StudyFolderCard({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.color,
    required this.icon,
    required this.onTap,
    this.coverBytes,
    this.artIcon,
    this.menuItems = const <StudyFolderMenuItem>[],
    this.onMenuSelected,
    super.key,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final Color color;
  final IconData icon;
  final IconData? artIcon;
  final VoidCallback onTap;
  final Uint8List? coverBytes;
  final List<StudyFolderMenuItem> menuItems;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final hasImage = coverBytes != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.appSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: .55)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: .11),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: <Widget>[
                if (hasImage)
                  Positioned.fill(
                    child: Image.memory(
                      coverBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (!hasImage)
                  Positioned(
                    right: -16,
                    top: 32,
                    child: Icon(
                      artIcon ?? icon,
                      size: 136,
                      color: color.withValues(alpha: .09),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: hasImage
                            ? <Color>[
                                Colors.black.withValues(alpha: .18),
                                Colors.black.withValues(alpha: .9),
                              ]
                            : <Color>[
                                color.withValues(alpha: .22),
                                AppColors.appSurface.withValues(alpha: .98),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  top: 0,
                  child: Container(
                    width: 76,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: .52),
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 25),
                          ),
                          const Spacer(),
                          if (menuItems.isNotEmpty)
                            PopupMenuButton<String>(
                              tooltip: 'Opções da pasta',
                              onSelected: onMenuSelected,
                              itemBuilder: (_) => menuItems
                                  .map(
                                    (item) => PopupMenuItem<String>(
                                      value: item.value,
                                      child: Row(
                                        children: <Widget>[
                                          Icon(
                                            item.icon,
                                            size: 19,
                                            color: item.danger
                                                ? AppColors.red
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(item.label),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.folder_outlined, color: color, size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              countLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasImage
                                    ? Colors.white70
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
