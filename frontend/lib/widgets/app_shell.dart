import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../services/session.dart';

class ExperimentItem {
  final int number;
  final String route;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const ExperimentItem({
    required this.number,
    required this.route,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class AppShell extends StatefulWidget {
  final Widget child;
  final String title;
  final String currentRoute;
  final void Function(String route) onNavigate;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
    required this.onNavigate,
    this.actions,
  });

  static List<ExperimentItem> get experiments => _AppShellState._experiments;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _expanded = true;

  static const List<ExperimentItem> _experiments = [
    ExperimentItem(
      number: 2, route: '/experiment-2/todo', label: 'Todo Management',
      description: 'Login-gated personal todo dashboard with priorities, categories, due dates, search and statistics.',
      icon: Icons.checklist_rounded, color: ExperimentPalette.todo),
    ExperimentItem(
      number: 3, route: '/experiment-3/blog', label: 'Micro Blogging',
      description: 'Share posts, follow users and like content in a mini Twitter-style timeline.',
      icon: Icons.forum_rounded, color: ExperimentPalette.blog),
    ExperimentItem(
      number: 4, route: '/experiment-4/food', label: 'Food Delivery',
      description: 'Browse restaurants and menus, manage a cart, checkout with delivery addresses and track orders.',
      icon: Icons.restaurant_rounded, color: ExperimentPalette.food),
    ExperimentItem(
      number: 5, route: '/experiment-5/classifieds', label: 'Classifieds',
      description: 'A marketplace to buy and sell used products with images, filters, favorites and seller contact.',
      icon: Icons.storefront_rounded, color: ExperimentPalette.classifieds),
    ExperimentItem(
      number: 6, route: '/experiment-6/leave', label: 'Leave Management',
      description: 'Apply for casual, medical, earned or other leave, track balances and approvals.',
      icon: Icons.event_available_rounded, color: ExperimentPalette.leave),
    ExperimentItem(
      number: 7, route: '/experiment-7/project-management', label: 'Project Management',
      description: 'Kanban-style task board with pending, in-progress and completed columns.',
      icon: Icons.dashboard_customize_rounded, color: ExperimentPalette.project),
    ExperimentItem(
      number: 8, route: '/experiment-8/survey', label: 'Online Survey',
      description: 'Answer 5 random questions per attempt, get scored results and track history.',
      icon: Icons.quiz_rounded, color: ExperimentPalette.survey),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compact = screenWidth < 900;
    final session = context.watch<Session>();

    Widget sidebar;
    if (compact) {
      sidebar = NavigationDrawer(
        backgroundColor: const Color(0xFF17163B),
        selectedIndex: _indexOf(widget.currentRoute),
        onDestinationSelected: (i) {
          Navigator.of(context).pop();
          widget.onNavigate(i == 0 ? '/' : _experiments[i - 1].route);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.science_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Full Stack Web Lab',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
            child: Text('MAIN', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
          ),
          const _NavDestination(icon: Icons.home_rounded, label: 'Dashboard', number: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 16, 4),
            child: Text('EXPERIMENTS', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
          ),
          for (var i = 0; i < _experiments.length; i++)
            _NavDestination(
              icon: _experiments[i].icon,
              label: '${_experiments[i].number}. ${_experiments[i].label}',
              number: i + 1,
            ),
          const Spacer(),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          UserFooter(session: session, compact: true),
        ],
      );
    } else {
      sidebar = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: _expanded ? 268 : 76,
        decoration: const BoxDecoration(
          color: Color(0xFF17163B),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(2, 0))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _expanded ? 18 : 14),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, color: Colors.white, size: 30),
                  if (_expanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Full Stack\nWeb Lab',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, height: 1.2)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 12),
            _SidebarItem(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              selected: widget.currentRoute == '/',
              expanded: _expanded,
              onTap: () => widget.onNavigate('/'),
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
                child: Text('EXPERIMENTS',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2)),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 10),
            ],
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _experiments.length,
                itemBuilder: (context, i) => _SidebarItem(
                  icon: _experiments[i].icon,
                  label: '${_experiments[i].number}. ${_experiments[i].label}',
                  selected: widget.currentRoute == _experiments[i].route,
                  expanded: _expanded,
                  onTap: () => widget.onNavigate(_experiments[i].route),
                ),
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            UserFooter(session: session, compact: false),
            IconButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.menu_open : Icons.menu, color: Colors.white54),
              tooltip: _expanded ? 'Collapse menu' : 'Expand menu',
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: compact ? sidebar : null,
      body: Row(
        children: [
          if (!compact) sidebar,
          Expanded(
            child: Column(
              children: [
                _Header(
                  title: widget.title,
                  onMenu: compact ? () => Scaffold.of(context).openDrawer() : null,
                  session: session,
                  actions: widget.actions,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.02, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(widget.currentRoute), child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _indexOf(String route) {
    if (route == '/') return 0;
    for (var i = 0; i < _experiments.length; i++) {
      if (_experiments[i].route == route) return i + 1;
    }
    return 0;
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.62)),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.72),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final int number;
  const _NavDestination({required this.icon, required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawerDestination(
      key: ValueKey(number),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 13.5)),
    );
  }
}

class UserFooter extends StatelessWidget {
  final Session session;
  final bool compact;
  const UserFooter({super.key, required this.session, required this.compact});

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: user == null
          ? const SizedBox.shrink()
          : Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFF4F46E5),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(user.isAdmin ? 'Administrator' : 'Student',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: () => context.read<Session>().logout(),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 19),
                  ),
                ],
              ],
            ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFF7F1D1D) : null,
    ));
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onMenu;
  final Session session;
  final List<Widget>? actions;

  const _Header({
    required this.title,
    this.onMenu,
    required this.session,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (onMenu != null) ...[
            IconButton(icon: const Icon(Icons.menu), onPressed: onMenu),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ),
          if (actions != null) ...[
            for (final a in actions!) ...[a, const SizedBox(width: 6)],
          ],
          if (session.user != null && onMenu == null)
            Tooltip(
              message: '${session.user!.name} (${session.user!.isAdmin ? 'Admin' : session.user!.email})',
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(session.user!.name.isNotEmpty ? session.user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}