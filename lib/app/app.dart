import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/scanner/scanner_page.dart';
import '../features/scanner/scanner_controller.dart';
import '../features/solution/solution_page.dart';
import '../features/history/history_page.dart';
import '../services/math_service.dart';
import '../services/history_service.dart';
import 'theme.dart';

class MathScannerApp extends StatelessWidget {
  const MathScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScannerController()),
        Provider(create: (_) => MathService()),
        Provider(create: (_) => HistoryService()),
      ],
      child: MaterialApp(
        title: 'Math Scanner AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ScannerPage(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const ScannerPage(),
          settings: settings,
        );

      case '/solving':
        return MaterialPageRoute(
          builder: (_) => const SolutionPage(),
          settings: settings,
        );

      case '/history':
        return MaterialPageRoute(
          builder: (_) => const HistoryPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const ScannerPage(),
          settings: settings,
        );
    }
  }
}
