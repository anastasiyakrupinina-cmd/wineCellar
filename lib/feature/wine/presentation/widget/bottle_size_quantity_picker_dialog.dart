import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';

class BottleSizeQuantityPickerDialog extends StatefulWidget {
  const BottleSizeQuantityPickerDialog({super.key});

  @override
  State<BottleSizeQuantityPickerDialog> createState() => _BottleSizeQuantityPickerDialogState();
}

class _BottleSizeQuantityPickerDialogState extends State<BottleSizeQuantityPickerDialog> {
  String _selected = '750ml';
  final _customController = TextEditingController();
  bool _isCustom = false;
  int _quantity = 1;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Bottle Size & Quantity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...WineBottle.standardSizes.map((size) => _chip(size)),
                _chip('Custom', isCustom: true),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. 500ml',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Quantity', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final size = _isCustom ? _customController.text.trim() : _selected;
            if (size.isEmpty) return;
            Navigator.pop(context, (bottleSize: size, quantity: _quantity));
          },
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _chip(String label, {bool isCustom = false}) {
    final isSelected = isCustom ? _isCustom : (_selected == label && !_isCustom);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          if (isCustom) {
            _isCustom = true;
          } else {
            _isCustom = false;
            _selected = label;
          }
        });
      },
      selectedColor: AppColors.darkBlue,
      backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.darkBlue,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}
