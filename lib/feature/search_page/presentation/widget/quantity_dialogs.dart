import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';

class AddQuantityDialog extends StatefulWidget {
  const AddQuantityDialog({super.key});

  @override
  State<AddQuantityDialog> createState() => _AddQuantityDialogState();
}

class _AddQuantityDialogState extends State<AddQuantityDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('How many to add?'),
      content: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: AppColors.darkBlue),
              onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
            ),
            Text('$_quantity', style: AppTextStyles.h2.copyWith(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.darkBlue),
              onPressed: () => setState(() => _quantity++),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, _quantity),
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class RemoveUnassignedDialog extends StatefulWidget {
  final int max;
  const RemoveUnassignedDialog({super.key, required this.max});

  @override
  State<RemoveUnassignedDialog> createState() => _RemoveUnassignedDialogState();
}

class _RemoveUnassignedDialogState extends State<RemoveUnassignedDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('How many to remove?'),
      content: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: AppColors.darkBlue),
              onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
            ),
            Text('$_quantity', style: AppTextStyles.h2.copyWith(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.darkBlue),
              onPressed: () { if (_quantity < widget.max) setState(() => _quantity++); },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, _quantity),
          child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
