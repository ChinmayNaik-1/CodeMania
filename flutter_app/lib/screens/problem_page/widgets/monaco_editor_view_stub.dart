import 'dart:async';
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
  
  String _lastSavedState = "";
  String _currentText = "";
  Timer? _typingDebouncer;

  @override
  void initState() {
    super.initState();
    _currentText = widget.code;
    _lastSavedState = widget.code;
    _controller = TextEditingController(text: widget.code);
    
    _controller.addListener(_onTextChanged);
    
    _attachController();
  }
  
  void _onTextChanged() {
    final newText = _controller.text;
    if (_currentText == newText) return;

    if (!_isUndoingOrRedoing) {
      final bool isSignificantChange = (newText.length - _currentText.length).abs() > 1;
      
      _currentText = newText;
      _redoStack.clear();
      
      if (isSignificantChange) {
        _typingDebouncer?.cancel();
        _pushUndo();
      } else {
        _typingDebouncer?.cancel();
        _typingDebouncer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) _pushUndo();
        });
      }
    } else {
      _currentText = newText;
    }
    
    widget.onCodeChanged(newText);
  }

  void _pushUndo() {
    if (_lastSavedState != _currentText) {
      _undoStack.add(_lastSavedState);
      _lastSavedState = _currentText;
      _updateState();
    }
  }

  void _undo() {
    _typingDebouncer?.cancel();
    if (_undoStack.isEmpty) return;
    
    if (_lastSavedState != _currentText) {
       _undoStack.add(_lastSavedState);
    }
    
    _isUndoingOrRedoing = true;
    _redoStack.add(_currentText);
    
    final previous = _undoStack.removeLast();
    _lastSavedState = previous;
    _currentText = previous;
    
    _controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    _isUndoingOrRedoing = false;
    _updateState();
  }
  
  void _redo() {
    _typingDebouncer?.cancel();
    if (_redoStack.isEmpty) return;
    
    _isUndoingOrRedoing = true;
    _undoStack.add(_currentText);
    
    final next = _redoStack.removeLast();
    _lastSavedState = next;
    _currentText = next;
    
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
      
      // Strip strings and comments before counting braces
      String codeForCounting = line
          .replaceAll(RegExp(r'".*?"'), '')
          .replaceAll(RegExp(r"'.*?'"), '')
          .replaceAll(RegExp(r'//.*'), '');
      
      int open = '{'.allMatches(codeForCounting).length;
      int close = '}'.allMatches(codeForCounting).length;
      
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
    _typingDebouncer?.cancel();
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
