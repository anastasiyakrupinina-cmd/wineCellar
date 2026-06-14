import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/feature/wine/data/models/purchase_record.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/repository/search_repository.dart';

class LogPurchaseDialog extends StatefulWidget {
  final String wineId;
  final List<String> existingSizes;
  const LogPurchaseDialog({super.key, required this.wineId, required this.existingSizes});

  @override
  State<LogPurchaseDialog> createState() => _LogPurchaseDialogState();
}

class _LogPurchaseDialogState extends State<LogPurchaseDialog> {
  bool _priceError = false;
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: '€');
  final _shopNameController = TextEditingController();
  final _customSizeController = TextEditingController();
  final _shopFocusNode = FocusNode();
  List<String> _shopOptions = [];
  List<String> _shopSuggestions = [];
  int _quantity = 1;
  DateTime _date = DateTime.now();
  String? _selectedSize;
  bool _isCustomSize = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSizes.isNotEmpty) {
      _selectedSize = widget.existingSizes.first;
    }
    getIt<SearchRepository>().getShopOptions().then((opts) {
      if (mounted) setState(() => _shopOptions = opts);
    });
    _shopFocusNode.addListener(_onShopFocusChanged);
    _shopNameController.addListener(_onShopTextChanged);
  }

  void _onShopFocusChanged() {
    if (!_shopFocusNode.hasFocus) setState(() => _shopSuggestions = []);
  }

  void _onShopTextChanged() {
    if (!_shopFocusNode.hasFocus) return;
    final q = _shopNameController.text.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() => _shopSuggestions = []);
      return;
    }
    setState(() {
      _shopSuggestions = _shopOptions
          .where((o) => o.toLowerCase().contains(q) && o.toLowerCase() != q)
          .take(6)
          .toList();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _currencyController.dispose();
    _shopNameController.dispose();
    _customSizeController.dispose();
    _shopFocusNode.removeListener(_onShopFocusChanged);
    _shopNameController.removeListener(_onShopTextChanged);
    _shopFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSizes = {...widget.existingSizes, ...WineBottle.standardSizes}.toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Purchase', style: AppTextStyles.h1.copyWith(fontSize: 24)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _field('Price *', _priceController, 'e.g. 45.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hasError: _priceError),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _field('Currency', _currencyController, r'$'),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            Text('Date', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.darkBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')} / ${_date.month.toString().padLeft(2, '0')} / ${_date.year}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Bottle Size', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: _selectedSize == null && !_isCustomSize,
                  onSelected: (_) => setState(() { _selectedSize = null; _isCustomSize = false; }),
                  selectedColor: AppColors.darkBlue,
                  backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: (_selectedSize == null && !_isCustomSize) ? Colors.white : AppColors.darkBlue,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                ),
                ...allSizes.map((size) => ChoiceChip(
                  label: Text(size),
                  selected: _selectedSize == size && !_isCustomSize,
                  onSelected: (_) => setState(() { _selectedSize = size; _isCustomSize = false; }),
                  selectedColor: AppColors.darkBlue,
                  backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: (_selectedSize == size && !_isCustomSize) ? Colors.white : AppColors.darkBlue,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                )),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _isCustomSize,
                  onSelected: (_) => setState(() { _isCustomSize = true; _selectedSize = null; }),
                  selectedColor: AppColors.darkBlue,
                  backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: _isCustomSize ? Colors.white : AppColors.darkBlue,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                ),
              ],
            ),
            if (_isCustomSize) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customSizeController,
                decoration: InputDecoration(
                  hintText: 'e.g. 500ml',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
            const SizedBox(height: 16),

            _shopField(),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final priceText = _priceController.text.trim();
                    final price = double.tryParse(priceText);
                    if (price == null) {
                      setState(() => _priceError = true);
                      return;
                    }
                    setState(() => _priceError = false);
                    final size = _isCustomSize ? _customSizeController.text.trim() : _selectedSize;
                    final record = PurchaseRecord(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      wineId: widget.wineId,
                      bottleSize: size?.isEmpty == true ? null : size,
                      quantity: _quantity,
                      price: price,
                      currency: _currencyController.text.trim().isEmpty ? '€' : _currencyController.text.trim(),
                      purchasedAt: _date,
                      shopName: _shopNameController.text.trim().isEmpty ? null : _shopNameController.text.trim(),
                    );
                    Navigator.pop(context, record);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopField() {
    final greyBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Store', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _shopNameController,
          focusNode: _shopFocusNode,
          decoration: InputDecoration(
            hintText: 'e.g. Wine Spectator Shop',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4)),
            border: greyBorder,
            enabledBorder: greyBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        if (_shopSuggestions.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _shopSuggestions
                  .map((option) => InkWell(
                        onTap: () {
                          _shopNameController.text = option;
                          _shopNameController.selection = TextSelection.fromPosition(
                            TextPosition(offset: option.length),
                          );
                          _shopFocusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.store_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(option, style: AppTextStyles.body.copyWith(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text, bool hasError = false}) {
    final greyBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final redBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: hasError ? (_) => setState(() => _priceError = false) : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4)),
            border: greyBorder,
            enabledBorder: hasError ? redBorder : greyBorder,
            focusedBorder: hasError
                ? OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2))
                : OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightBlue, width: 2)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        SizedBox(
          height: 18,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  child: Text('Required',
                      style: const TextStyle(color: AppColors.error, fontSize: 12)),
                )
              : null,
        ),
      ],
    );
  }
}
