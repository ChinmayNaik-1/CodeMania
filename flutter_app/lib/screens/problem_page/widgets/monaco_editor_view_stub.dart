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
  
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoingOrRedoing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    
    _controller.addListener(_onTextChanged);
    
    _attachController();
  }
  
  void _onTextChanged() {
    final newText = _controller.text;
    if (!_isUndoingOrRedoing) {
      if (_undoStack.isEmpty || _undoStack.last != newText) {
        // Only push to undo stack if it's actually a change from the current state
        final currentState = _undoStack.isEmpty ? widget.code : _undoStack.last;
        if (newText != currentState) {
          _undoStack.add(currentState);
          _redoStack.clear();
          _updateState();
        }
      }
    }
    widget.onCodeChanged(newText);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _isUndoingOrRedoing = true;
    _redoStack.add(_controller.text);
    final previous = _undoStack.removeLast();
    _controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    _isUndoingOrRedoing = false;
    _updateState();
  }
  
  void _redo() {
    if (_redoStack.isEmpty) return;
    _isUndoingOrRedoing = true;
    _undoStack.add(_controller.text);
    final next = _redoStack.removeLast();
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _isUndoingOrRedoing = false;
    _updateState();
  }

  void _updateState() {
    if (widget.controller != null) {
      widget.controller?.updateState(
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
        canFormat: widget.language != 'python',
      );
    }
  }

  void _attachController() {
    widget.controller?.attach(
      onUndo: _undo,
      onRedo: _redo,
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
      
      int open = '{'.allMatches(line).length;
      int close = '}'.allMatches(line).length;
      
      int decreaseBefore = line.startsWith('}') ? 1 : 0;
      indent = (indent - decreaseBefore).clamp(0, 999);
      
      buffer.write('    ' * indent);
      buffer.write(line);
      if (i < lines.length - 1) buffer.writeln();
      
      indent += (open - close) + decreaseBefore;
      indent = indent.clamp(0, 999);
    }
    
    final newText = buffer.toString();
    if (newText != text) {
      // It will trigger _onTextChanged and correctly add the unformatted code to the undo stack!
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
      // Programmatic change from outside (e.g., reset button)
      // This will trigger _onTextChanged and add to undo stack!
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
