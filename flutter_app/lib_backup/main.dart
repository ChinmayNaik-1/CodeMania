import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/router/app_router.dart';
import 'services/api_service.dart';
import 'services/runtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

    return MaterialApp.router(
      title: 'CodeMania',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA116),
          secondary: Color(0xFF2CBB5D),
          surface: Color(0xFF282828),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: Color(0xFFFFA116),
          labelColor: Color(0xFFFFA116),
          unselectedLabelColor: Color(0xFF8A8A8A),
        ),
        dividerColor: const Color(0xFF2A2A2A),
      ),
      routerConfig: router,
    );
  }
}
