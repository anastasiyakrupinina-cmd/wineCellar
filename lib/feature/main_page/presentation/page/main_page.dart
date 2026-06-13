import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/app_settings_cubit.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/core/widget/text_field.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_state.dart';
import 'package:wine_cellar/feature/main_page/presentation/widget/app_bar.dart';
import 'package:wine_cellar/feature/main_page/presentation/widget/main_list.dart';
import 'package:wine_cellar/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:wine_cellar/feature/wine/data/models/catalog_filters.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/repository/search_repository.dart';

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with AutoRouteAwareStateMixin<MainPage> {
  String _searchQuery = '';
  String _sortBy = 'spot';
  String? _selectedCabinet;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  MainCubit? _mainCubit;
  CatalogFilters _filterOptions = const CatalogFilters();

  @override
  void didPopNext() {
    _mainCubit?.loadWines();
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    _mainCubit?.loadWines();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final options = await getIt<SearchRepository>().getFilterOptions();
      if (mounted) setState(() => _filterOptions = options);
    } catch (_) {}
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  

  List<WineModel> _filterWines(List<WineModel> wines) {
    return wines.where((w) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      return w.name.toLowerCase().contains(query) ||
          (w.winery?.toLowerCase().contains(query) ?? false) ||
          (w.region?.toLowerCase().contains(query) ?? false) ||
          (w.country?.toLowerCase().contains(query) ?? false) ||
          (w.vintage?.toString().contains(query) ?? false) ||
          ((w.type ?? '').toLowerCase().contains(query)) ||
          (w.grapes?.any((g) => g.toLowerCase().contains(query)) ?? false);
    }).toList();
  }

  Map<String, Map<String, List<WineModel>>> _groupWines(List<WineModel> wines) {
    Map<String, Map<String, List<WineModel>>> grouped = {};

    for (var wine in wines) {
      List<String> locations = [];
      if (wine.cellarLocation != null && wine.cellarLocation!.isNotEmpty) {
        locations = wine.cellarLocation!.split(' ; ');
      } else {
        locations.add('Unassigned');
      }

      final assignedSpotCount = locations
          .where((loc) => loc.contains('Spot '))
          .fold<int>(0, (count, loc) {
            final spotStr = loc.split('Spot ').last;
            return count + spotStr.split(',').where((s) => s.trim().isNotEmpty).length;
          });
      final unassignedRemainder = (wine.quantity - assignedSpotCount).clamp(0, wine.quantity);

      for (var loc in locations) {
        String cabinet = 'Unassigned';
        String shelf = '';
        List<String> spots = [];

        if (loc != 'Unassigned') {
          final parts = loc.split(' > ');
          if (parts.isNotEmpty) cabinet = parts[0].trim();
          if (parts.length > 1) shelf = parts[1].trim();

          if (loc.contains('Spot ')) {
            final spotStr = loc.split('Spot ').last;
            spots = spotStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }
        }

        grouped.putIfAbsent(cabinet, () => {});
        grouped[cabinet]!.putIfAbsent(shelf, () => []);

        if (spots.isNotEmpty) {
          for (var spot in spots) {
            final singleBottle = wine.copyWith(quantity: 1, cellarLocation: '$cabinet > $shelf > Spot $spot');
            grouped[cabinet]![shelf]!.add(singleBottle);
          }
        } else {
          int quantityForLocation = wine.quantity;
          if (loc == 'Unassigned' && locations.length > 1) {
            quantityForLocation = unassignedRemainder;
          }

          if (quantityForLocation <= 0) {
            continue;
          }

          final wineForShelf = locations.length > 1
              ? wine.copyWith(cellarLocation: loc, quantity: quantityForLocation)
              : wine;
          grouped[cabinet]![shelf]!.add(wineForShelf);
        }
      }
    }

    
    final sortedCabinets = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Unassigned') return -1;
        if (b == 'Unassigned') return 1;
        return a.compareTo(b);
      });
    Map<String, Map<String, List<WineModel>>> finalGrouped = {};

    for (var cabinet in sortedCabinets) {
      finalGrouped[cabinet] = {};
      final sortedShelves = grouped[cabinet]!.keys.toList()..sort();

      for (var shelf in sortedShelves) {
        final winesList = grouped[cabinet]![shelf]!;
        finalGrouped[cabinet]![shelf] = _sortWines(winesList); 
      }
    }
    return finalGrouped;
  }

  List<WineModel> _sortWines(List<WineModel> wines) {
    wines.sort((a, b) {
      if (_sortBy == 'rating') {
        return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
      } else if (_sortBy == 'vintage') {
        return (b.vintage ?? 0).compareTo(a.vintage ?? 0);
      } else if (_sortBy == 'name') {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (_sortBy == 'price') {
        double getPrice(WineModel w) {
          if (w.prices != null && w.prices!.isNotEmpty) {
            final p = w.prices!.first.price;
            return p;
          }
          return 0.0;
        }

        return getPrice(b).compareTo(getPrice(a)); 
      } else {
        int getSpot(WineModel w) {
          if (w.cellarLocation == null) return 0;
          final firstLoc = w.cellarLocation!.split(' ; ').first;
          final parts = firstLoc.split(' > ');
          final spotStr = parts.last
              .replaceAll('Spot ', '')
              .split(',')
              .first
              .replaceAll(RegExp(r'[^0-9]'), '');
          return int.tryParse(spotStr) ?? 0;
        }

        return getSpot(a).compareTo(getSpot(b));
      }
    });
    return wines;
  }

  

  void _showAddWineBottomSheet(BuildContext context) {
    final cubit = context.read<MainCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.baseWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: EdgeInsets.only(
          left: 28,
          right: 28,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
        ),
        child: _AddWineForm(cubit: cubit),
      ),
    ).then((_) {
      cubit.loadWines();
      _loadFilterOptions();
    });
  }

  void _showEditWineBottomSheet(BuildContext context, WineModel wine) {
    final cubit = context.read<MainCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.baseWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: EdgeInsets.only(
          left: 28,
          right: 28,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
        ),
        child: _AddWineForm(cubit: cubit, wineToEdit: wine),
      ),
    ).then((_) => cubit.loadWines());
  }

  void _showFilterOptions(BuildContext context) {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.baseWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            ),
            child: _buildFilterContent(context, setModalState),
          );
        },
      ),
    );
  }

  Widget _buildFilterContent(BuildContext context, StateSetter setModalState) {
    return Column(
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
        Text('Filters', style: AppTextStyles.h1.copyWith(fontSize: 28)),
        const SizedBox(height: 24),
        Text(
          'SORT BY',
          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSortChip('Location', 'spot', Icons.place_outlined, setModalState),
            _buildSortChip('A-Z', 'name', Icons.sort_by_alpha_rounded, setModalState),
            _buildSortChip('Rating', 'rating', Icons.star_outline_rounded, setModalState),
            _buildSortChip('Year', 'vintage', Icons.calendar_today_rounded, setModalState),
            _buildSortChip('Price', 'price', Icons.attach_money_rounded, setModalState),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'VIEW MODE',
          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settingsState) {
            return Container(
              decoration: BoxDecoration(color: AppColors.softWhite, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                title: Text(
                  settingsState.showCabinetView ? 'Cabinet view' : 'List view',
                  style: AppTextStyles.body,
                ),
                value: settingsState.showCabinetView,
                onChanged: (value) {
                  context.read<AppSettingsCubit>().toggleCabinetView(value);
                  setModalState(() {});
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                activeThumbColor: AppColors.darkBlue,
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        AppButton(text: 'Done', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setModalState(() => _sortBy = value);
        setState(() => _sortBy = value);
      },
      selectedColor: AppColors.darkBlue,
      backgroundColor: AppColors.softWhite,
      labelStyle: AppTextStyles.body.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<MainCubit>()..loadWines();
        _mainCubit = cubit;
        return cubit;
      },
      
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.baseWhite,
              extendBodyBehindAppBar: true,
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: FloatingActionButton(
                  shape: CircleBorder(),
                  onPressed: () => _showAddWineBottomSheet(context),
                  child: const Icon(Icons.add),
                ),
              ),
              appBar: MainAppBar(
                onFilterPressed: () => _showFilterOptions(context),
                
                onAddPressed: () => _showAddWineBottomSheet(context),
              ),
              body: BlocBuilder<MainCubit, MainState>(
                builder: (context, state) {
                  final showCabinetView = context.watch<AppSettingsCubit>().state.showCabinetView;

                  if (state is MainLoading) return const Center(child: CircularProgressIndicator());
                  if (state is MainLoaded) {
                    final filteredAndSortedWines = _sortWines(_filterWines(state.wines));
                    final groupedWines = _groupWines(filteredAndSortedWines);
                    final totalWineCountById = <String, int>{};
                    for (final wine in filteredAndSortedWines) {
                      totalWineCountById[wine.id] = (totalWineCountById[wine.id] ?? 0) + wine.quantity;
                    }

                    return MainWineList(
                      searchController: _searchController,
                      groupedWines: groupedWines,
                      totalWineCountById: totalWineCountById,
                      showCabinetView: showCabinetView,
                      selectedCabinet: _selectedCabinet,
                      onCabinetSelected: (name) => setState(() => _selectedCabinet = name),
                      onWineLongPress: (wine) => _showEditWineBottomSheet(context, wine),
                      allOptions: _filterOptions.allOptions,
                      onSuggestionTap: (s) {
                        _searchController.text = s;
                        setState(() => _searchQuery = s);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddWineForm extends StatefulWidget {
  final MainCubit cubit;
  final WineModel? wineToEdit;
  const _AddWineForm({required this.cubit, this.wineToEdit});

  @override
  State<_AddWineForm> createState() => _AddWineFormState();
}

class _AddWineFormState extends State<_AddWineForm> {
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
            _AutocompleteFormField(
              label: 'Wine Name *',
              hint: 'e.g. Chateau Margaux',
              controller: _nameController,
              options: _filterOptions.names,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _AutocompleteFormField(
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
                  child: _AutocompleteFormField(
                    label: 'Country',
                    hint: 'e.g. France',
                    controller: _countryController,
                    options: _filterOptions.countries,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AutocompleteFormField(
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

class _AutocompleteFormField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> options;
  final String? Function(String?)? validator;
  final bool isMultiValue;

  const _AutocompleteFormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.options = const [],
    this.validator,
    this.isMultiValue = false,
  });

  @override
  State<_AutocompleteFormField> createState() => _AutocompleteFormFieldState();
}

class _AutocompleteFormFieldState extends State<_AutocompleteFormField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  double _fieldWidth = 0;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _onTextChanged();
    } else {
      _hideOverlay();
    }
  }

  String _getQuery() {
    if (widget.isMultiValue) {
      return widget.controller.text.split(',').last.trim().toLowerCase();
    }
    return widget.controller.text.trim().toLowerCase();
  }

  void _onTextChanged() {
    if (_isSelecting || !mounted || !_focusNode.hasFocus) return;
    final q = _getQuery();
    if (q.isEmpty) {
      _hideOverlay();
      return;
    }
    _suggestions = widget.options
        .where((o) => o.toLowerCase().contains(q))
        .take(6)
        .toList();
    if (_suggestions.isEmpty) {
      _hideOverlay();
    } else if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _fieldWidth, maxHeight: 280),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final option = _suggestions[i];
                  return InkWell(
                    onTap: () => _selectOption(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(option, style: AppTextStyles.body.copyWith(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _suggestions = [];
  }

  void _selectOption(String option) {
    _isSelecting = true;
    if (widget.isMultiValue) {
      final parts = widget.controller.text.split(',');
      final existing = parts
          .sublist(0, parts.length - 1)
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      widget.controller.text = [...existing, option].join(', ');
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
      _hideOverlay();
    } else {
      widget.controller.text = option;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: option.length),
      );
      _hideOverlay();
      _focusNode.unfocus();
    }
    _isSelecting = false;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth;
        return CompositedTransformTarget(
          link: _layerLink,
          child: AppTextField(
            label: widget.label,
            hint: widget.hint,
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
          ),
        );
      },
    );
  }
}
