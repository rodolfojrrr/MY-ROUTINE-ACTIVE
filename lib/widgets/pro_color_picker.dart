import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Color?> showProColorPicker(
  BuildContext context, {
  required String title,
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _ProColorPickerDialog(
      title: title,
      initialColor: initialColor,
    ),
  );
}

class ProColorTile extends StatelessWidget {
  const ProColorTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final selected = await showProColorPicker(
            context,
            title: title,
            initialColor: color,
          );
          if (selected != null) onChanged(selected);
        },
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: .42)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: .25),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _hex(color),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.tune_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProColorPickerDialog extends StatefulWidget {
  const _ProColorPickerDialog({
    required this.title,
    required this.initialColor,
  });

  final String title;
  final Color initialColor;

  @override
  State<_ProColorPickerDialog> createState() => _ProColorPickerDialogState();
}

class _ProColorPickerDialogState extends State<_ProColorPickerDialog> {
  late HSVColor hsv;
  late final TextEditingController hexController;

  @override
  void initState() {
    super.initState();
    hsv = HSVColor.fromColor(widget.initialColor);
    hexController = TextEditingController(text: _hex(widget.initialColor));
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() {
      hsv = value;
      hexController.text = _hex(value.toColor());
      hexController.selection = TextSelection.collapsed(
        offset: hexController.text.length,
      );
    });
  }

  void _setHex(String value) {
    final color = _parseHex(value);
    if (color != null) setState(() => hsv = HSVColor.fromColor(color));
  }

  @override
  Widget build(BuildContext context) {
    final color = hsv.toColor();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 112,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: .3),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _hex(color),
                  style: TextStyle(
                    color: ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('pro-color-hex-field'),
                controller: hexController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: const InputDecoration(
                  labelText: 'Código hexadecimal',
                  hintText: '#2F8CFF',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                onChanged: _setHex,
              ),
              const SizedBox(height: 16),
              _ColorSlider(
                label: 'Matiz',
                value: hsv.hue,
                max: 360,
                color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                onChanged: (value) => _setHsv(hsv.withHue(value)),
              ),
              _ColorSlider(
                label: 'Saturação',
                value: hsv.saturation,
                max: 1,
                color: color,
                onChanged: (value) => _setHsv(hsv.withSaturation(value)),
              ),
              _ColorSlider(
                label: 'Luminosidade',
                value: hsv.value,
                max: 1,
                color: color,
                onChanged: (value) => _setHsv(hsv.withValue(value)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você pode usar os controles ou colar qualquer cor HEX.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
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
        FilledButton.icon(
          key: const Key('pro-color-confirm'),
          onPressed: () => Navigator.pop(context, color),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Usar esta cor'),
        ),
      ],
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: .18),
            ),
            child: Slider(
              value: value.clamp(0, max),
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color? _parseHex(String raw) {
  final value = raw.replaceAll('#', '').trim();
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}
