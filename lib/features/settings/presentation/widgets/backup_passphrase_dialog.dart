import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BackupPassphraseDialog extends StatefulWidget {
  final bool isRestore;
  const BackupPassphraseDialog({super.key, this.isRestore = false});

  @override
  State<BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<BackupPassphraseDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: Text(widget.isRestore ? 'Restore Passphrase' : 'Backup Passphrase', style: const TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: InputDecoration(
          hintText: widget.isRestore ? 'Enter your backup passphrase' : 'Enter a strong passphrase',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.deepInk)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAction, foregroundColor: Colors.white),
          onPressed: () {
            if (_controller.text.length >= 8) {
              Navigator.pop(context, _controller.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passphrase must be at least 8 characters'), behavior: SnackBarBehavior.floating),
              );
            }
          },
          child: Text(widget.isRestore ? 'Restore' : 'Export'),
        ),
      ],
    );
  }
}
