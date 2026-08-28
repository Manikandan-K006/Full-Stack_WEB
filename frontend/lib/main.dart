import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'services/session.dart';
import 'core/routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FullStackWebLabApp());
}

class FullStackWebLabApp extends StatelessWidget {
  const FullStackWebLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()..restore()),
      ],
      child: MaterialApp(
        title: 'Full Stack Web Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppRouter(),
      ),
    );
  }
}
