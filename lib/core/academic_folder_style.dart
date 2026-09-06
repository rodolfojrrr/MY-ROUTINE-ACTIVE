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
    Color(0xFFEF5350),
    Color(0xFFFFC107),
    Color(0xFF8BC34A),
    Color(0xFF26A69A),
    Color(0xFF26C6DA),
    Color(0xFF5C6BC0),
    Color(0xFFAB47BC),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
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
    AcademicFolderIconOption(
      id: 'folder',
      label: 'Pasta',
      icon: Icons.folder_rounded,
    ),
    AcademicFolderIconOption(
      id: 'notes',
      label: 'Resumos',
      icon: Icons.sticky_note_2_rounded,
    ),
    AcademicFolderIconOption(
      id: 'quiz',
      label: 'Exercícios',
      icon: Icons.quiz_rounded,
    ),
    AcademicFolderIconOption(
      id: 'design',
      label: 'Design',
      icon: Icons.palette_rounded,
    ),
    AcademicFolderIconOption(
      id: 'dart',
      label: 'Dart / Flutter',
      icon: Icons.flutter_dash_rounded,
    ),
    AcademicFolderIconOption(
      id: 'python',
      label: 'Python',
      icon: Icons.data_object_rounded,
    ),
    AcademicFolderIconOption(
      id: 'java',
      label: 'Java',
      icon: Icons.coffee_rounded,
    ),
    AcademicFolderIconOption(
      id: 'javascript',
      label: 'JavaScript',
      icon: Icons.javascript_rounded,
    ),
    AcademicFolderIconOption(
      id: 'typescript',
      label: 'TypeScript',
      icon: Icons.integration_instructions_rounded,
    ),
    AcademicFolderIconOption(
      id: 'c_language',
      label: 'C',
      icon: Icons.memory_rounded,
    ),
    AcademicFolderIconOption(
      id: 'cpp',
      label: 'C++',
      icon: Icons.settings_suggest_rounded,
    ),
    AcademicFolderIconOption(
      id: 'csharp',
      label: 'C# / .NET',
      icon: Icons.grid_view_rounded,
    ),
    AcademicFolderIconOption(
      id: 'kotlin',
      label: 'Kotlin / Android',
      icon: Icons.phone_android_rounded,
    ),
    AcademicFolderIconOption(
      id: 'php',
      label: 'PHP',
      icon: Icons.webhook_rounded,
    ),
    AcademicFolderIconOption(
      id: 'html',
      label: 'HTML',
      icon: Icons.html_rounded,
    ),
    AcademicFolderIconOption(
      id: 'css',
      label: 'CSS',
      icon: Icons.style_rounded,
    ),
    AcademicFolderIconOption(
      id: 'terminal',
      label: 'Terminal / Shell',
      icon: Icons.terminal_rounded,
    ),
    AcademicFolderIconOption(
      id: 'linux',
      label: 'Linux / Sistemas',
      icon: Icons.computer_rounded,
    ),
    AcademicFolderIconOption(
      id: 'mobile',
      label: 'Desenvolvimento móvel',
      icon: Icons.developer_mode_rounded,
    ),
    AcademicFolderIconOption(
      id: 'api',
      label: 'API e integração',
      icon: Icons.api_rounded,
    ),
    AcademicFolderIconOption(
      id: 'software_architecture',
      label: 'Arquitetura de software',
      icon: Icons.architecture_rounded,
    ),
    AcademicFolderIconOption(
      id: 'testing',
      label: 'Testes de software',
      icon: Icons.fact_check_rounded,
    ),
    AcademicFolderIconOption(
      id: 'bugs',
      label: 'Debug e qualidade',
      icon: Icons.bug_report_rounded,
    ),
    AcademicFolderIconOption(
      id: 'ai',
      label: 'Inteligência artificial',
      icon: Icons.psychology_rounded,
    ),
    AcademicFolderIconOption(
      id: 'analytics',
      label: 'Análise de dados',
      icon: Icons.analytics_rounded,
    ),
    AcademicFolderIconOption(
      id: 'statistics',
      label: 'Estatística',
      icon: Icons.query_stats_rounded,
    ),
    AcademicFolderIconOption(
      id: 'calculus',
      label: 'Cálculo',
      icon: Icons.calculate_rounded,
    ),
    AcademicFolderIconOption(
      id: 'logic',
      label: 'Lógica',
      icon: Icons.schema_rounded,
    ),
    AcademicFolderIconOption(
      id: 'libras',
      label: 'Libras',
      icon: Icons.sign_language_rounded,
    ),
    AcademicFolderIconOption(
      id: 'accessibility',
      label: 'Acessibilidade',
      icon: Icons.accessibility_new_rounded,
    ),
    AcademicFolderIconOption(
      id: 'languages',
      label: 'Idiomas',
      icon: Icons.translate_rounded,
    ),
    AcademicFolderIconOption(
      id: 'communication',
      label: 'Comunicação',
      icon: Icons.record_voice_over_rounded,
    ),
    AcademicFolderIconOption(
      id: 'writing',
      label: 'Português e escrita',
      icon: Icons.spellcheck_rounded,
    ),
    AcademicFolderIconOption(
      id: 'research',
      label: 'Pesquisa científica',
      icon: Icons.biotech_rounded,
    ),
    AcademicFolderIconOption(
      id: 'law',
      label: 'Direito e legislação',
      icon: Icons.gavel_rounded,
    ),
    AcademicFolderIconOption(
      id: 'business',
      label: 'Gestão e negócios',
      icon: Icons.business_center_rounded,
    ),
    AcademicFolderIconOption(
      id: 'people',
      label: 'Pessoas e equipes',
      icon: Icons.groups_rounded,
    ),
    AcademicFolderIconOption(
      id: 'presentation',
      label: 'Apresentação',
      icon: Icons.co_present_rounded,
    ),
    AcademicFolderIconOption(
      id: 'history',
      label: 'História e sociedade',
      icon: Icons.history_edu_rounded,
    ),
    AcademicFolderIconOption(
      id: 'project',
      label: 'Projeto',
      icon: Icons.rocket_launch_rounded,
    ),
    AcademicFolderIconOption(
      id: 'certificate',
      label: 'Certificado',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  static Color colorFor(SyncEntity entity, {Color? fallback}) {
    final stored = entity.payload['folderColor'];
    if (stored is num) return Color(stored.toInt());
    if (fallback != null) return fallback;
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
    return Icons.folder_rounded;
  }

  static Color toolColorFor(SyncEntity content, String toolId, Color fallback) {
    final raw = content.payload['toolFolderColors'];
    if (raw is Map) {
      final stored = raw[toolId];
      if (stored is num) return Color(stored.toInt());
    }
    return fallback;
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
