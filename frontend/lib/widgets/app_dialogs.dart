import 'package:flutter/material.dart';

class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    Color? confirmColor,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: confirmColor ?? const Color(0xFFEF4444), size: 34),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(height: 1.45, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class AppDialogs {
  static void showSnack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              color: error ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: error ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
      ));
  }

  static String friendlyError(Object? error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'Something went wrong. Please try again.';
  }
}

class FormFieldError {
  static String? of(Object? error) {
    if (error is String && error.isNotEmpty) return error;
    return null;
  }
}