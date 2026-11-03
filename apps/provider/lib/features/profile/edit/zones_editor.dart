import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Work zones as removable chips, with a field to add one more.
class ZonesEditor extends StatefulWidget {
  const ZonesEditor({
    required this.zones,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    super.key,
  });

  final List<String> zones;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String? errorText;

  @override
  State<ZonesEditor> createState() => _ZonesEditorState();
}

class _ZonesEditorState extends State<ZonesEditor> {
  final _zone = TextEditingController();

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  void _add() {
    widget.onAdd(_zone.text);
    _zone.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.zones.isNotEmpty) ...[
        Wrap(
          spacing: ManoSpacing.sm,
          runSpacing: ManoSpacing.sm,
          children: [
            for (final zone in widget.zones)
              ManoChoiceChip(
                label: zone,
                onRemove: () => widget.onRemove(zone),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ManoTextField(
              label: 'Agregar zona',
              controller: _zone,
              helperText: 'Barrio o localidad, por ejemplo Suba',
              errorText: widget.errorText,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
            ),
          ),
          IconButton(
            onPressed: _add,
            tooltip: 'Agregar zona',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );
}
