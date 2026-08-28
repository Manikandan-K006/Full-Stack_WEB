import 'package:flutter/material.dart';

/// Provides simple, animated inner-navigation for experiment screens so each
/// module can push/pop its own pages while the global sidebar stays visible.
///
/// Usage:
///   final nav = FeatureNavigator.of(context);
///   nav.push(_SomeDetailPage(...));   // uses a fade-through transition
///   nav.pop();
class FeatureNavigator extends StatefulWidget {
  final Widget home;
  final Color? backColor;
  final String? backLabel;

  const FeatureNavigator({super.key, required this.home, this.backColor, this.backLabel});

  static FeatureNavigatorState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<FeatureNavigatorState>();

  static FeatureNavigatorState of(BuildContext context) =>
      context.findAncestorStateOfType<FeatureNavigatorState>()!;

  @override
  State<FeatureNavigator> createState() => FeatureNavigatorState();
}

class FeatureNavigatorState extends State<FeatureNavigator> {
  final List<Widget> _pages = [];
  int get depth => _pages.length;

  void push(Widget page) {
    setState(() => _pages.add(page));
  }

  void pushReplacement(Widget page) {
    setState(() {
      if (_pages.isNotEmpty) _pages.removeLast();
      _pages.add(page);
    });
  }

  void pop() {
    if (_pages.isEmpty) return;
    setState(() => _pages.removeLast());
  }

  void popUntilRoot() {
    setState(() => _pages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.home,
        for (final page in _pages)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_pages.indexOf(page)),
              child: page,
            ),
          ),
      ],
    );
  }
}
