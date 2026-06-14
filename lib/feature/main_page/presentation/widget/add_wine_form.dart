import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/autocomplete_form_field.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/core/widget/text_field.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:wine_cellar/feature/wine/data/models/catalog_filters.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/repository/search_repository.dart';
import 'package:wine_cellar/feature/wine/presentation/widget/storage_location_dialog.dart';

class AddWineForm extends StatefulWidget {
  final MainCubit cubit;
  final WineModel? wineToEdit;
  const AddWineForm({super.key, required this.cubit, this.wineToEdit});

  @override
  State<AddWineForm> createState() => _AddWineFormState();
}

class _AddWineFormState extends State<AddWineForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wineryController = TextEditingController();
  final _grapesController = TextEditingController();
  final _regionController = TextEditingController();
  final _countryController = TextEditingController();
  final _vintageController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noticeController = TextEditingController();
  String _selectedType = 'Red';
  String _selectedBottleSize = '750ml';
  bool _isCustomBottleSize = false;
  final _customBottleSizeController = TextEditingController();
  int _quantity = 1;
  late final String _wineId;
  CatalogFilters _filterOptions = const CatalogFilters();

  final List<String> _types = ['Red', 'White', 'Rose', 'Sparkling', 'Dessert'];

  @override
  void initState() {
    super.initState();
    if (widget.wineToEdit != null) {
      final wine = widget.wineToEdit!;
      _wineId = wine.id;
      _nameController.text = wine.name;
      _wineryController.text = wine.winery ?? '';
      _grapesController.text = wine.grapes?.join(', ') ?? '';
      _regionController.text = wine.region ?? '';
      _countryController.text = wine.country ?? '';
      _vintageController.text = wine.vintage?.toString() ?? '';
      _priceController.text = wine.prices?.firstOrNull?.price.toString() ?? '';
      _descriptionController.text = wine.description ?? '';
      _noticeController.text = widget.wineToEdit!.notice ?? '';
      _selectedType = wine.type ?? 'Red';
      _quantity = wine.quantity;
    } else {
      _wineId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    getIt<SearchRepository>().getFilterOptions().then((opts) {
      if (mounted) setState(() => _filterOptions = opts);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wineryController.dispose();
    _grapesController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    _vintageController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
    _customBottleSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wineToEdit != null;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Wine' : 'Add Wine', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AutocompleteFormField(
                label: 'Wine Name *',
                hint: 'e.g. Chateau Margaux',
                controller: _nameController,
                options: _filterOptions.names,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AutocompleteFormField(
                label: 'Grape Varieties',
                hint: 'e.g. Cabernet Sauvignon, Merlot',
                controller: _grapesController,
                options: _filterOptions.grapes,
                isMultiValue: true,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AutocompleteFormField(
                      label: 'Country',
                      hint: 'e.g. France',
                      controller: _countryController,
                      options: _filterOptions.countries,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AutocompleteFormField(
                      label: 'Winery',
                      hint: 'e.g. Ruffino',
                      controller: _wineryController,
                      options: _filterOptions.wineries,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Year',
                      hint: 'e.g. 2015',
                      controller: _vintageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Price (€)',
                      hint: 'e.g. 150',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Bottle Size', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...WineBottle.standardSizes.map((size) {
                      final isSelected = !_isCustomBottleSize && _selectedBottleSize == size;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _isCustomBottleSize = false;
                            _selectedBottleSize = size;
                          }),
                          selectedColor: AppColors.darkBlue,
                          backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.darkBlue,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Custom'),
                        selected: _isCustomBottleSize,
                        onSelected: (_) => setState(() => _isCustomBottleSize = true),
                        selectedColor: AppColors.darkBlue,
                        backgroundColor: AppColors.lightBlue.withValues(alpha: 0.1),
                        labelStyle: AppTextStyles.caption.copyWith(
                          color: _isCustomBottleSize ? Colors.white : AppColors.darkBlue,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        showCheckmark: false,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCustomBottleSize) ...[
                const SizedBox(height: 8),
                AppTextField(
                  label: '',
                  hint: 'e.g. 500ml',
                  controller: _customBottleSizeController,
                ),
              ],
              const SizedBox(height: 24),
              AppTextField(
                label: 'Description & Notes',
                hint: 'Aromas, taste, food pairings...',
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'My Notice',
                hint: 'e.g. Let it breathe for 1 hour, a gift from John...',
                controller: _noticeController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantity', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: AppColors.darkBlue),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
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
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Wine',
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final bottleSize = _isCustomBottleSize
                      ? _customBottleSizeController.text.trim()
                      : _selectedBottleSize;
                  final resolvedSize = bottleSize.isEmpty ? '750ml' : bottleSize;
                  final grapesRaw = _grapesController.text.trim();
                  final grapesList = grapesRaw.isNotEmpty
                      ? grapesRaw.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList()
                      : null;
                  final newWine = WineModel(
                    id: _wineId,
                    name: _nameController.text.trim(),
                    winery: _wineryController.text.trim().isNotEmpty ? _wineryController.text.trim() : null,
                    grapes: grapesList,
                    type: _selectedType,
                    country: _countryController.text.trim(),
                    region: _regionController.text.trim(),
                    vintage: int.tryParse(_vintageController.text.trim()) ?? 0,
                    description: _descriptionController.text.trim(),
                    notice: _noticeController.text.trim().isEmpty ? null : _noticeController.text.trim(),
                    quantity: _quantity,
                    bottles: [
                      WineBottle(
                        id: '${_wineId}_${resolvedSize}_${DateTime.now().microsecondsSinceEpoch}',
                        wineId: _wineId,
                        bottleSize: resolvedSize,
                        quantity: _quantity,
                      ),
                    ],
                  );
                  await widget.cubit.saveWine(newWine);
                  if (!context.mounted) return;
                  await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (ctx) => StorageLocationDialog(wine: newWine),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
