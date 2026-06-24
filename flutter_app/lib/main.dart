import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/router/app_router.dart';
import 'package:codemania/providers/theme_provider.dart';
import 'package:codemania/core/theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/runtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Edge-to-edge: the OS bars are transparent and each screen paints its own
  // solid theme background behind them (icon brightness is set per-theme below).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  usePathUrlStrategy();
  ApiService.init();
  await RuntimeService.refresh();
  runApp(const ProviderScope(child: CodeManiaApp()));
}

class CodeManiaApp extends ConsumerWidget {
  const CodeManiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CodeMania',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        // Resolve the effective brightness (handles ThemeMode.system too) and
        // drive the transparent system bars' icon brightness to match, so the
        // status bar / nav bar always read clearly against the theme background.
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
