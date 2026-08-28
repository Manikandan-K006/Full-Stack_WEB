import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/auth_gate.dart';
import '../../widgets/lab_shell.dart';
import '../../widgets/loading_widget.dart';
import '../../services/session.dart';

/// Top-level router. Restores the session, then shows either the login
/// screen or the app shell with the selected experiment.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  String _currentRoute = '/';

  @override
  Widget build(BuildContext context) {
    return Consumer<Session>(
      builder: (context, session, _) {
        if (session.restoring) {
          return const LoadingWidget(fullScreen: true, message: 'Loading Full Stack Web Lab…');
        }
        if (!session.isAuthenticated) {
          return const AuthGate();
        }
        return LabShell(
          currentRoute: _currentRoute,
          onNavigate: (route) => setState(() => _currentRoute = route),
        );
      },
    );
  }
}