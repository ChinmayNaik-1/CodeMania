import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

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
  static int _counter = 0;

  late final String _containerId;
  late final String _viewType;
  Timer? _pollTimer;
  String _lastCode = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _counter += 1;
    _containerId = 'codemania-monaco-$_counter';
    _viewType = 'codemania-monaco-view-$_counter';
    _lastCode = widget.code;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%';
      return div;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createEditor();
      _startPolling();
    });
  }

  String _monacoLanguage(String language) {
    switch (language) {
      case 'cpp':
        return 'cpp';
      case 'javascript':
        return 'javascript';
      case 'java':
        return 'java';
      case 'python':
      default:
        return 'python';
    }
  }

  void _createEditor() {
    js_util.callMethod(
      html.window,
      'codemaniaMonacoCreateEditor',
      [
        _containerId,
        {
          'value': widget.code,
          'language': _monacoLanguage(widget.language),
          'theme': widget.theme,
        }
      ],
    );
  }

  void _setCode(String code) {
    js_util.callMethod(html.window, 'codemaniaMonacoSetCode', [_containerId, code]);
  }

  void _setLanguage(String language) {
    js_util.callMethod(
      html.window,
      'codemaniaMonacoSetLanguage',
      [_containerId, _monacoLanguage(language)],
    );
  }

  void _layout() {
    js_util.callMethod(html.window, 'codemaniaMonacoLayout', [_containerId]);
  }

  String _getCode() {
    final value = js_util.callMethod(html.window, 'codemaniaMonacoGetCode', [_containerId]);
    return (value ?? '').toString();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_disposed) return;
      final current = _getCode();
      if (current != _lastCode) {
        _lastCode = current;
        widget.onCodeChanged(current);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MonacoEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.language != widget.language) {
      _setLanguage(widget.language);
    }

    if (oldWidget.theme != widget.theme) {
      js_util.callMethod(html.window, 'codemaniaMonacoSetTheme', [widget.theme]);
    }

    if (oldWidget.code != widget.code && widget.code != _lastCode) {
      _lastCode = widget.code;
      _setCode(widget.code);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) _layout();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    js_util.callMethod(html.window, 'codemaniaMonacoDispose', [_containerId]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
