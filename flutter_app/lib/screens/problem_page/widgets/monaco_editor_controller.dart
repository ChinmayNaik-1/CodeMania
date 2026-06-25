import 'dart:ui';

class MonacoEditorController {
  VoidCallback? _undoAction;
  VoidCallback? _redoAction;
  VoidCallback? _formatAction;

  void attach({
    required VoidCallback onUndo,
    required VoidCallback onRedo,
    required VoidCallback onFormat,
  }) {
    _undoAction = onUndo;
    _redoAction = onRedo;
    _formatAction = onFormat;
  }

  void detach() {
    _undoAction = null;
    _redoAction = null;
    _formatAction = null;
  }

  void undo() => _undoAction?.call();
  void redo() => _redoAction?.call();
  void formatDocument() => _formatAction?.call();
}
