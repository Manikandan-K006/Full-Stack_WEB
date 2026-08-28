import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/session.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/feature_navigator.dart';

class AdminModerationView extends StatelessWidget {
  const AdminModerationView({super.key});

  void _pop(BuildContext context) {
    final nav = FeatureNavigator.maybeOf(context);
    if (nav != null) {
      nav.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<Session>().user?.isAdmin == true;
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(title: 'Moderation', onBack: () => _pop(context)),
          Expanded(
            child: isAdmin
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE6E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: ExperimentPalette.classifieds.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shield_outlined,
                                    color: ExperimentPalette.classifieds, size: 26),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Admin moderation',
                                        style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark)),
                                    SizedBox(height: 4),
                                    Text(
                                      'The classifieds backend currently exposes no admin '
                                      'moderation endpoints. Listings are self-moderated by '
                                      'their owners: sellers can edit details, mark items as '
                                      'sold or delete their own listings.',
                                      style: TextStyle(
                                          fontSize: 12.5, height: 1.45, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const EmptyState(
                          icon: Icons.verified_outlined,
                          title: 'No moderation queue',
                          subtitle:
                              'When the backend adds admin listing endpoints, remove/restore '
                              'actions will appear here',
                        ),
                      ],
                    ),
                  )
                : const EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Admins only',
                    subtitle: 'This view is available only to administrator accounts',
                  ),
          ),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _BackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}