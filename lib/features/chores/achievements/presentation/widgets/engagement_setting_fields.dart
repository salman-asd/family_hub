import 'package:flutter/material.dart';

class IntegerSettingField extends StatefulWidget {
  const IntegerSettingField({
    required this.fieldId,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onValidityChanged,
    super.key,
  });

  final String fieldId;
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool> onValidityChanged;

  @override
  State<IntegerSettingField> createState() => _IntegerSettingFieldState();
}

class _IntegerSettingFieldState extends State<IntegerSettingField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant IntegerSettingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        _controller.text != '${widget.value}') {
      _controller.value = TextEditingValue(
        text: '${widget.value}',
        selection: TextSelection.collapsed(offset: '${widget.value}'.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: widget.label),
    onChanged: (text) {
      final parsed = _parseNumber(text);
      final valid =
          parsed != null && parsed >= widget.min && parsed <= widget.max;
      widget.onValidityChanged(valid);
      if (valid) widget.onChanged(parsed);
    },
  );
}

class TextSettingField extends StatefulWidget {
  const TextSettingField({
    required this.fieldId,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onValidityChanged,
    this.maxLength = 40,
    super.key,
  });

  final String fieldId;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onValidityChanged;
  final int maxLength;

  @override
  State<TextSettingField> createState() => _TextSettingFieldState();
}

class _TextSettingFieldState extends State<TextSettingField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant TextSettingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    maxLength: widget.maxLength,
    decoration: InputDecoration(labelText: widget.label),
    onChanged: (text) {
      final valid = text.trim().isNotEmpty && text.length <= widget.maxLength;
      widget.onValidityChanged(valid);
      if (valid) widget.onChanged(text);
    },
  );
}

int? _parseNumber(String text) => int.tryParse(
  text
      .replaceAll('০', '0')
      .replaceAll('১', '1')
      .replaceAll('২', '2')
      .replaceAll('৩', '3')
      .replaceAll('৪', '4')
      .replaceAll('৫', '5')
      .replaceAll('৬', '6')
      .replaceAll('৭', '7')
      .replaceAll('৮', '8')
      .replaceAll('৯', '9'),
);
