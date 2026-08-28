import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/experiment2_todo/screens/todo_home_screen.dart';
import '../features/experiment3_blog/screens/blog_home_screen.dart';
import '../features/experiment4_food/screens/food_home_screen.dart';
import '../features/experiment5_classifieds/screens/classifieds_home_screen.dart';
import '../features/experiment6_leave/screens/leave_home_screen.dart';
import '../features/experiment7_project/screens/project_home_screen.dart';
import '../features/experiment8_survey/screens/survey_home_screen.dart';
import 'app_shell.dart';

class LabShell extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;

  const LabShell({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  String get _title {
    switch (currentRoute) {
      case '/':
        return 'Dashboard';
      case '/experiment-2/todo':
        return 'Experiment 2 - Todo Management';
      case '/experiment-3/blog':
        return 'Experiment 3 - Micro Blogging';
      case '/experiment-4/food':
        return 'Experiment 4 - Food Delivery';
      case '/experiment-5/classifieds':
        return 'Experiment 5 - Classifieds';
      case '/experiment-6/leave':
        return 'Experiment 6 - Leave Management';
      case '/experiment-7/project-management':
        return 'Experiment 7 - Project Management';
      case '/experiment-8/survey':
        return 'Experiment 8 - Online Survey';
      default:
        return 'Full Stack Web Lab';
    }
  }

  Widget get _screen {
    switch (currentRoute) {
      case '/':
        return DashboardScreen(onNavigate: onNavigate);
      case '/experiment-2/todo':
        return const TodoHomeScreen();
      case '/experiment-3/blog':
        return const BlogHomeScreen();
      case '/experiment-4/food':
        return const FoodHomeScreen();
      case '/experiment-5/classifieds':
        return const ClassifiedsHomeScreen();
      case '/experiment-6/leave':
        return const LeaveHomeScreen();
      case '/experiment-7/project-management':
        return const ProjectHomeScreen();
      case '/experiment-8/survey':
        return const SurveyHomeScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _title,
      currentRoute: currentRoute,
      onNavigate: onNavigate,
      child: _screen,
    );
  }
}