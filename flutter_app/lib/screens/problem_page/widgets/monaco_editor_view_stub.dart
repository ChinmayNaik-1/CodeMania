import 'package:flutter/material.dart';

class MonacoEditorView extends StatefulWidget {
  const MonacoEditorView({
    super.key,
    required this.code,
    required this.language,
    required this.theme,
    required this.onCodeChanged,
    this.controller,
  });

  final String code;
  final String language;
  final String theme;
  final ValueChanged<String> onCodeChanged;
  final dynamic controller;

  @override
  State<MonacoEditorView> createState() => _MonacoEditorViewState();
}

class _MonacoEditorViewState extends State<MonacoEditorView> {
  late final TextEditingController _controller;
  late final UndoHistoryController _undoController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _undoController = UndoHistoryController();
    
    _controller.addListener(() => widget.onCodeChanged(_controller.text));
    _undoController.addListener(_updateState);
    
    _attachController();
  }

  void _updateState() {
    if (widget.controller != null) {
      widget.controller?.updateState(
        canUndo: _undoController.value.canUndo,
        canRedo: _undoController.value.canRedo,
        canFormat: widget.language != 'python',
      );
    }
  }

  void _attachController() {
    widget.controller?.attach(
      onUndo: () => _undoController.undo(),
      onRedo: () => _undoController.redo(),
      onFormat: _formatCode,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateState());
  }

  void _formatCode() {
    if (widget.language == 'python') return; // Cannot auto-indent python safely
    
    final text = _controller.text;
    final lines = text.split('\n');
    int indent = 0;
    final buffer = StringBuffer();
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        buffer.writeln();
        continue;
      }
      
      if (line.startsWith('}')) {
        indent = (indent - 1).clamp(0, 999);
      }
      
      buffer.write('    ' * indent);
      buffer.write(line);
      if (i < lines.length - 1) buffer.writeln();
      
      int open = '{'.allMatches(line).length;
      int close = '}'.allMatches(line).length;
      indent += (open - close);
      indent = indent.clamp(0, 999);
    }
    
    final newText = buffer.toString();
    if (newText != text) {
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
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
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _undoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      undoController: _undoController,
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
