import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/app_settings_cubit.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/dependencies/get_it.dart';
import 'package:home_wine/core/style/app_text_style.dart';
import 'package:home_wine/core/widget/app_snackbar.dart';
import 'package:home_wine/core/widget/button.dart';
import 'package:home_wine/core/widget/text_field.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_state.dart';
import 'package:home_wine/feature/main_page/presentation/widget/app_bar.dart';
import 'package:home_wine/feature/main_page/presentation/widget/main_list.dart';
import 'package:home_wine/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';

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
          (w.region?.toLowerCase().contains(query) ?? false) ||
          (w.country?.toLowerCase().contains(query) ?? false) ||
          (w.vintage?.toString().contains(query) ?? false) ||
          ((w.type ?? '').toLowerCase().contains(query));
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

      final spotLocationsCount = locations.where((loc) => loc.contains('Spot ')).length;
      final unassignedRemainder = (wine.quantity - spotLocationsCount).clamp(0, wine.quantity);

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
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _countryController = TextEditingController();
  final _vintageController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noticeController = TextEditingController();
  String _selectedType = 'Red';
  int _quantity = 1;
  String? _cellarLocation;
  late final String _wineId;

  final List<String> _types = ['Red', 'White', 'Rose', 'Sparkling', 'Dessert'];

  @override
  void initState() {
    super.initState();
    if (widget.wineToEdit != null) {
      final wine = widget.wineToEdit!;
      _wineId = wine.id;
      _nameController.text = wine.name;
      _regionController.text = wine.region ?? '';
      _countryController.text = wine.country ?? '';
      _vintageController.text = wine.vintage?.toString() ?? '';
      _priceController.text = wine.prices?.firstOrNull?.price.toString() ?? '';
      _descriptionController.text = wine.description ?? '';
      _noticeController.text = widget.wineToEdit!.notice ?? '';
      _selectedType = wine.type ?? 'Red';
      _quantity = wine.quantity;
      _cellarLocation = wine.cellarLocation;
    } else {
      _wineId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    _vintageController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wineToEdit != null;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
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
            AppTextField(label: 'Wine Name *', hint: 'e.g. Chateau Margaux', controller: _nameController),
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
                      backgroundColor: AppColors.lightBlue.withOpacity(0.1),
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
              children: [
                Expanded(
                  child: AppTextField(label: 'Country', hint: 'e.g. France', controller: _countryController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(label: 'Region', hint: 'e.g. Bordeaux', controller: _regionController),
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
                    label: 'Price (\$)',
                    hint: 'e.g. 150',
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
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
            InkWell(
              onTap: () async {
                final dummyWine = WineModel(
                  id: _wineId,
                  name: _nameController.text.trim(),
                  quantity: _quantity,
                );
                final res = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) => StorageLocationDialog(wine: dummyWine),
                );
                if (res != null) {
                  setState(() {
                    _cellarLocation = res['location'] as String;
                    _quantity = res['quantity'] as int;
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Storage Location', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _cellarLocation?.isNotEmpty == true
                                ? _cellarLocation!.replaceAll(' ; ', '\n')
                                : 'Set location',
                            textAlign: TextAlign.end,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _cellarLocation?.isNotEmpty == true
                                  ? AppColors.darkBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                
                
                _cellarLocation != null && _cellarLocation!.isNotEmpty
                    ? Text('$_quantity', style: AppTextStyles.h2.copyWith(fontSize: 18))
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.1),
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
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  AppSnackBar.show(context, message: 'Please enter a wine name', isError: true);
                  return;
                }
                final newWine = WineModel(
                  id: _wineId,
                  name: _nameController.text.trim(),
                  type: _selectedType,
                  country: _countryController.text.trim(),
                  region: _regionController.text.trim(),
                  vintage: int.tryParse(_vintageController.text.trim()) ?? 0,
                  description: _descriptionController.text.trim(),
                  notice: _noticeController.text.trim().isEmpty ? null : _noticeController.text.trim(),
                  quantity: _quantity,
                  cellarLocation: _cellarLocation,
                  
                  
                );
                widget.cubit.saveWine(newWine);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
