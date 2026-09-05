import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'sync_entity.dart';

class AcademicFolderIconOption {
  const AcademicFolderIconOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class AcademicFolderStyle {
  static const colors = <Color>[
    Color(0xFF2F8CFF),
    Color(0xFF6558E8),
    Color(0xFF12B8A6),
    Color(0xFF00A7D6),
    Color(0xFFFF8B3D),
    Color(0xFFE5488C),
    Color(0xFF7B61FF),
    Color(0xFF607D9B),
  ];

  static const icons = <AcademicFolderIconOption>[
    AcademicFolderIconOption(
      id: 'code',
      label: 'Programação',
      icon: Icons.code_rounded,
    ),
    AcademicFolderIconOption(
      id: 'database',
      label: 'Banco de dados',
      icon: Icons.storage_rounded,
    ),
    AcademicFolderIconOption(
      id: 'algorithm',
      label: 'Algoritmos',
      icon: Icons.account_tree_rounded,
    ),
    AcademicFolderIconOption(
      id: 'network',
      label: 'Redes',
      icon: Icons.hub_rounded,
    ),
    AcademicFolderIconOption(
      id: 'security',
      label: 'Segurança',
      icon: Icons.shield_rounded,
    ),
    AcademicFolderIconOption(
      id: 'web',
      label: 'Web',
      icon: Icons.language_rounded,
    ),
    AcademicFolderIconOption(
      id: 'cloud',
      label: 'Nuvem',
      icon: Icons.cloud_outlined,
    ),
    AcademicFolderIconOption(
      id: 'memory',
      label: 'Hardware',
      icon: Icons.memory_rounded,
    ),
    AcademicFolderIconOption(
      id: 'math',
      label: 'Matemática',
      icon: Icons.functions_rounded,
    ),
    AcademicFolderIconOption(
      id: 'science',
      label: 'Ciência',
      icon: Icons.science_rounded,
    ),
    AcademicFolderIconOption(
      id: 'book',
      label: 'Teoria',
      icon: Icons.menu_book_rounded,
    ),
    AcademicFolderIconOption(
      id: 'school',
      label: 'Acadêmico',
      icon: Icons.school_rounded,
    ),
  ];

  static Color colorFor(SyncEntity entity) {
    final stored = entity.payload['folderColor'];
    if (stored is num) return Color(stored.toInt());
    var seed = 0;
    for (final unit in entity.id.codeUnits) {
      seed = ((seed * 31) + unit) & 0x7FFFFFFF;
    }
    final index = seed % colors.length;
    return colors[index];
  }

  static IconData iconFor(SyncEntity entity) =>
      iconForId(entity.payload['folderIcon'] as String?);

  static IconData iconForId(String? id) {
    for (final option in icons) {
      if (option.id == id) return option.icon;
    }
    return Icons.code_rounded;
  }

  static Uint8List? coverBytes(SyncEntity entity) {
    final encoded = entity.payload['coverImageBase64'] as String? ?? '';
    if (encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  static Color readableColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : AppColors.background;
}
