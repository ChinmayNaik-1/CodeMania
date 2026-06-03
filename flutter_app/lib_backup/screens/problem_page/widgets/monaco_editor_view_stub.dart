import 'package:flutter/material.dart';

class MonacoEditorView extends StatefulWidget {
  const MonacoEditorView({
    super.key,
    required this.code,
    required this.language,
    required this.theme,
    required this.onCodeChanged,
  });

  final String code;
  final String language;
  final String theme;
  final ValueChanged<String> onCodeChanged;

  @override
  State<MonacoEditorView> createState() => _MonacoEditorViewState();
}

class _MonacoEditorViewState extends State<MonacoEditorView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _controller.addListener(() => widget.onCodeChanged(_controller.text));
  }

  @override
  void didUpdateWidget(covariant MonacoEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller.text = widget.code;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
    );
  }
}
