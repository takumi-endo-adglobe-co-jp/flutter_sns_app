import 'package:flutter/material.dart';
import '../constant/app_strings.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancelButton),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show delete confirmation dialog
  static Future<void> showDeleteConfirmation({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppStrings.deleteConfirmTitle,
        message: AppStrings.deleteConfirmMessage,
        confirmText: AppStrings.deleteConfirmButton,
        onConfirm: onConfirm,
      ),
    );
  }
}
