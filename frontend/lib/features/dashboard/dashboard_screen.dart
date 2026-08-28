import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/app_shell.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(String route)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final experiments = AppShell.experiments;
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1300 ? 4 : (width > 900 ? 3 : (width > 600 ? 2 : 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBanner().animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, curve: Curves.easeOut),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Experiments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${experiments.length} experiments • Flutter + FastAPI + MongoDB',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < experiments.length; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _ExperimentCard(
                        item: experiments[i],
                        index: i,
                        onTap: () => onNavigate?.call(experiments[i].route),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17163B), Color(0xFF312E81), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x55312E81), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'FULL STACK WEB LAB',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 2.4,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Seven real applications. One platform.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todo • Micro Blogging • Food Delivery • Classifieds • Leave Management • Project Management • Online Survey',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _pill('Flutter Web', Icons.flutter_dash),
                  _pill('FastAPI', Icons.code),
                  _pill('MongoDB', Icons.storage),
                  _pill('JWT Auth', Icons.shield_outlined),
                ],
              ),
            ],
          );
          if (!wide) return text;
          return Row(
            children: [
              Expanded(flex: 3, child: text),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.science_rounded, size: 56, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  final ExperimentItem item;
  final int index;
  final VoidCallback onTap;

  const _ExperimentCard({required this.item, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accentColor: item.color,
      padding: const EdgeInsets.all(18),
      hoverElevation: 10,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Exp ${item.number}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: item.color,
                side: BorderSide(color: item.color.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Experiment'),
            ),
          ),
        ],
      ),
    );
  }
}