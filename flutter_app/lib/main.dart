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
  
  // Enable edge-to-edge display
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
    );
  }
}
