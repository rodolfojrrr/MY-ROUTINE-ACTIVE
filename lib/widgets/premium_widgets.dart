import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.45,
          colors: <Color>[Color(0xFF07383F), AppColors.background],
          stops: <double>[0, .58],
        ),
      ),
      child: child,
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor ?? AppColors.border.withValues(alpha: .85),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: content,
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.color = AppColors.green,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.1,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: <Widget>[
              Icon(icon, color: AppColors.textMuted, size: 40),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (caption != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmDeleteButton extends StatelessWidget {
  const ConfirmDeleteButton({required this.onDelete, super.key});

  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Excluir',
      color: AppColors.red,
      icon: const Icon(Icons.delete_outline),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir registro?'),
            content: const Text(
              'A exclusão será sincronizada com o outro aparelho.',
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
        if (confirmed == true) await onDelete();
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.minItemWidth = 280,
    this.spacing = 14,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count =
            (constraints.maxWidth / minItemWidth).floor().clamp(1, 4).toInt();
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: count == 1 ? 2.25 : 1.55,
          children: children,
        );
      },
    );
  }
}

Future<DateTime?> pickAppDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
}

double parseMoney(String value) {
  final normalized = value
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
