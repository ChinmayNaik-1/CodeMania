import 'package:flutter/foundation.dart';
import 'dart:ui';

class MonacoEditorController extends ChangeNotifier {
  VoidCallback? _undoAction;
  VoidCallback? _redoAction;
  VoidCallback? _formatAction;

  bool _canUndo = false;
  bool _canRedo = false;
  bool _canFormat = true;

  bool get canUndo => _canUndo;
  bool get canRedo => _canRedo;
  bool get canFormat => _canFormat;

  void updateState({required bool canUndo, required bool canRedo, bool canFormat = true}) {
    _canUndo = canUndo;
    _canRedo = canRedo;
    _canFormat = canFormat;
    notifyListeners();
  }

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
