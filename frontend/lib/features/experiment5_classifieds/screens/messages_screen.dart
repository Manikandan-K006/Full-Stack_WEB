import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../models/contact_message.dart';
import '../services/classified_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _loading = true;
  String? _error;
  List<ContactMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await ClassifiedService.myMessages();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppDialogs.friendlyError(e);
      });
    }
  }

  void _pop() {
    final nav = FeatureNavigator.maybeOf(context);
    if (nav != null) {
      nav.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(title: 'Inbox', onBack: _pop),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading messages…')
                : _error != null
                    ? ErrorWidgetView(message: _error!, onRetry: _load)
                    : _messages.isEmpty
                        ? const EmptyState(
                            icon: Icons.forum_outlined,
                            title: 'No messages yet',
                            subtitle:
                                'Messages you send or receive about listings will appear here',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _messages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _buildTile(_messages[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(ContactMessage message) {
    final currentUserId = context.read<Session>().user?.id ?? '';
    final incoming = message.isIncoming(currentUserId);
    return AnimatedCard(
      accentColor: ExperimentPalette.classifieds,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ExperimentPalette.classifieds),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.relativeTime(message.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (incoming ? AppColors.primary : ExperimentPalette.classifieds)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  incoming ? 'Incoming' : 'Sent',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: incoming ? AppColors.primary : ExperimentPalette.classifieds,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  incoming ? 'From ${message.name}' : 'You contacted the seller',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.message,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.grey.shade700),
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