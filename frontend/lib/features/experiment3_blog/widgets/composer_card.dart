import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class ComposerCard extends StatefulWidget {
  final Future<bool> Function(String content) onSubmit;

  const ComposerCard({super.key, required this.onSubmit});

  @override
  State<ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<ComposerCard> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final length = _controller.text.trim().length;
    return !_busy && length > 0 && length <= AppConstants.postMaxLength;
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (!_canSubmit) return;
    setState(() => _busy = true);
    final ok = await widget.onSubmit(content);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final over = length > AppConstants.postMaxLength;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExperimentPalette.blog.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            maxLength: AppConstants.postMaxLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$length/${AppConstants.postMaxLength}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: over ? AppColors.danger : Colors.grey.shade600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.blog),
                icon: _busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(_busy ? 'Posting…' : 'Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
