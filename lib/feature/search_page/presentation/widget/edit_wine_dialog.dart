import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';

class EditWineDialog extends StatefulWidget {
  final WineModel wine;

  const EditWineDialog({super.key, required this.wine});

  @override
  State<EditWineDialog> createState() => _EditWineDialogState();
}

class _EditWineDialogState extends State<EditWineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _wineryController;
  late final TextEditingController _grapesController;
  late final TextEditingController _countryController;
  late final TextEditingController _regionController;
  late final TextEditingController _vintageController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noticeController;
  late String _selectedType;

  final List<String> _types = ['Red', 'White', 'Rose', 'Sparkling', 'Dessert'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wine.name);
    _wineryController = TextEditingController(text: widget.wine.winery ?? '');
    _grapesController = TextEditingController(text: widget.wine.grapes?.join(', ') ?? '');
    _countryController = TextEditingController(text: widget.wine.country ?? '');
    _regionController = TextEditingController(text: widget.wine.region ?? '');
    _vintageController = TextEditingController(text: widget.wine.vintage?.toString() ?? '');
    _priceController = TextEditingController(text: widget.wine.prices?.firstOrNull?.price.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.wine.description ?? '');
    _noticeController = TextEditingController(text: widget.wine.notice ?? '');
    _selectedType = widget.wine.type ?? 'Red';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wineryController.dispose();
    _grapesController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _vintageController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Wine', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                const SizedBox(height: 24),
                _buildTextField('Wine Name *', _nameController, 'e.g. Chateau Margaux',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                _buildTextField('Winery', _wineryController, 'e.g. Château Margaux'),
                const SizedBox(height: 16),
                _buildTextField('Grape Varieties', _grapesController, 'e.g. Cabernet Sauvignon, Merlot'),
                const SizedBox(height: 16),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Country', _countryController, 'e.g. France')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Region', _regionController, 'e.g. Bordeaux')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Year', _vintageController, 'e.g. 2015', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField('Price (€)', _priceController, 'e.g. 150',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Description & Notes', _descriptionController, 'Aromas, taste, food pairings...',
                    maxLines: 4, keyboardType: TextInputType.multiline),
                const SizedBox(height: 16),
                _buildTextField('My Notice', _noticeController, 'e.g. Let it breathe for 1 hour...',
                    maxLines: 3, keyboardType: TextInputType.multiline),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final grapesRaw = _grapesController.text.trim();
                        final grapesList = grapesRaw.isNotEmpty
                            ? grapesRaw.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList()
                            : null;
                        final updatedWine = widget.wine.copyWith(
                          name: _nameController.text.trim(),
                          winery: _wineryController.text.trim().isEmpty ? null : _wineryController.text.trim(),
                          grapes: grapesList,
                          type: _selectedType,
                          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
                          region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
                          vintage: _vintageController.text.trim().isEmpty
                              ? null
                              : int.tryParse(_vintageController.text.trim()) ?? 0,
                          description: _descriptionController.text.trim().isEmpty
                              ? null
                              : _descriptionController.text.trim(),
                          notice: _noticeController.text.trim().isEmpty ? null : _noticeController.text.trim(),
                          prices: _priceController.text.isNotEmpty
                              ? [WinePrice(
                                  price: double.tryParse(_priceController.text.trim()) ?? 0,
                                  currency: '€',
                                  merchant: widget.wine.prices?.firstOrNull?.merchant,
                                )]
                              : widget.wine.prices,
                        );
                        Navigator.pop(context, updatedWine);
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _types.map((type) {
              final isSelected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: AppColors.darkBlue,
                  backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: isSelected ? Colors.white : AppColors.darkBlue,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
