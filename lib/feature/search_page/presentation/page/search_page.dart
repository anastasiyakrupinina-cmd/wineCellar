import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/app_snackbar.dart';
import 'package:wine_cellar/core/widget/bottle_wine.dart';
import 'package:wine_cellar/core/widget/text_field.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_state.dart';
import 'package:wine_cellar/feature/wine/presentation/widget/bottle_size_quantity_picker_dialog.dart';
import 'package:wine_cellar/feature/wine/presentation/widget/storage_location_dialog.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/repository/wine_repository.dart';
import 'package:wine_cellar/feature/wine/presentation/cubit/wine_search_cubit.dart';
import 'package:wine_cellar/feature/wine/presentation/cubit/wine_search_state.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_state.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final WineSearchCubit _searchCubit;
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCubit = getIt<WineSearchCubit>();
    _searchCubit.searchWines();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchCubit.searchWines(query: _searchController.text);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _searchCubit.loadMoreWines();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
    final bool isDesktop = screenWidth > 600;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _searchCubit),
        BlocProvider(create: (context) => getIt<MainCubit>()..loadWines()),
      ],
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.baseWhite,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Catalog', style: AppTextStyles.h1),
            centerTitle: !isDesktop,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: AppTextField(
                      hint: 'Name, winery, region, country, type',
                      controller: _searchController,
                      prefixIcon: Icons.search,
                      suffixIcon: _searchController.text.isNotEmpty ? Icons.close_rounded : null,
                      onSuffixTap: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        _searchCubit.searchWines(query: '');
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocConsumer<WineSearchCubit, WineSearchState>(
                  listener: (context, state) {
                    if (state is WineSearchError) {
                      AppSnackBar.show(context, message: state.message, isError: true);
                    }
                  },
                  builder: (context, state) {
                    if (state is WineSearchLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.darkBlue));
                    }

                    if (state is WineSearchSuccess) {
                      if (state.wines.isEmpty) {
                        return Center(
                          child: Text(
                            'Nothing found 🍷',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: state.isLastPage ? state.wines.length : state.wines.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= state.wines.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return _SearchWineCard(wine: state.wines[index]);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchWineCard extends StatelessWidget {
  final WineModel wine;

  const _SearchWineCard({required this.wine});

  @override
  Widget build(BuildContext context) {
    final String subtitle = [
      wine.region,
      wine.vintage?.toString(),
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    return GestureDetector(
      onTap: () {
        context.router.push(WineDetailRoute(wine: wine));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlue.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      color: AppColors.lightBlue.withValues(alpha: 0.2),
                      child: Center(
                              child: AbstractWineBottle(type: wine.type, size: 110),
                            ),
                    ),
                  ),
                  if (wine.averageRating != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: AppColors.darkBlue),
                            const SizedBox(width: 4),
                            Text(
                              wine.averageRating!.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: BlocBuilder<WishlistCubit, WishlistState>(
                      builder: (context, state) {
                        final wishlisted = context.read<WishlistCubit>().isWishlisted(wine.id);
                        return GestureDetector(
                          onTap: () => context.read<WishlistCubit>().toggle(wine),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              wishlisted ? Icons.bookmark : Icons.bookmark_border,
                              color: AppColors.darkBlue,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wine.name,
                          style: AppTextStyles.h2.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle.isNotEmpty ? subtitle : 'Unknown',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<MainCubit, MainState>(
                    builder: (context, state) {
                      int quantity = 0;
                      WineModel? cellarWine;
                      if (state is MainLoaded) {
                        cellarWine = state.wines.where((w) => w.id == wine.id).firstOrNull;
                        if (cellarWine != null) {
                          quantity = cellarWine.quantity;
                        }
                      }

                      if (quantity > 0 && cellarWine != null) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: AppColors.darkBlue, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _removeOneBottle(context, cellarWine!),
                              ),
                              Text(
                                '$quantity',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: AppColors.darkBlue, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () async {
                                  final w = cellarWine!;
                                  final picked = await showDialog<({String bottleSize, int quantity})>(
                                    context: context,
                                    builder: (ctx) => const BottleSizeQuantityPickerDialog(),
                                  );
                                  if (picked == null || !context.mounted) return;
                                  final res = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (ctx) => StorageLocationDialog(
                                      wine: w.copyWith(quantity: w.quantity + picked.quantity),
                                      bottleSize: picked.bottleSize,
                                      lockInitialSpots: true,
                                      maxNewSpots: picked.quantity,
                                    ),
                                  );
                                  if (res == null || !context.mounted) return;
                                  final existingBottles = w.bottles?.isNotEmpty == true
                                      ? w.bottles!
                                      : [WineBottle(
                                          id: '${w.id}_default',
                                          wineId: w.id,
                                          bottleSize: '750ml',
                                          quantity: w.quantity,
                                        )];
                                  final existing = existingBottles
                                      .where((b) => b.bottleSize == picked.bottleSize)
                                      .firstOrNull;
                                  final List<WineBottle> newBottles;
                                  if (existing != null) {
                                    newBottles = existingBottles
                                        .map((b) => b.bottleSize == picked.bottleSize
                                            ? b.copyWith(quantity: b.quantity + picked.quantity)
                                            : b)
                                        .toList();
                                  } else {
                                    newBottles = [
                                      ...existingBottles,
                                      WineBottle(
                                        id: '${w.id}_${picked.bottleSize}_${DateTime.now().microsecondsSinceEpoch}',
                                        wineId: w.id,
                                        bottleSize: picked.bottleSize,
                                        quantity: picked.quantity,
                                      ),
                                    ];
                                  }
                                  context.read<MainCubit>().updateBottleSizes(w, newBottles);
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () async {
                          WineModel wineToAdd;
                          try {
                            wineToAdd = await getIt<WineRepository>().getWineDetails(wine.id);
                          } catch (e) {
                            wineToAdd = wine;
                          }

                          if (!context.mounted) return;
                          final picked = await showDialog<({String bottleSize, int quantity})>(
                            context: context,
                            builder: (ctx) => const BottleSizeQuantityPickerDialog(),
                          );
                          if (picked == null || !context.mounted) return;

                          final res = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (ctx) => StorageLocationDialog(wine: wineToAdd.copyWith(quantity: picked.quantity), bottleSize: picked.bottleSize),
                          );
                          if (res != null && context.mounted) {
                            final loc = res['location'] as String;
                            final qty = res['quantity'] as int;
                            context.read<MainCubit>().saveWine(
                              wineToAdd.copyWith(
                                cellarLocation: loc,
                                quantity: qty,
                                bottles: [
                                  WineBottle(
                                    id: '${wineToAdd.id}_${DateTime.now().microsecondsSinceEpoch}',
                                    wineId: wineToAdd.id,
                                    bottleSize: picked.bottleSize,
                                    quantity: qty,
                                  ),
                                ],
                              ),
                            );
                            AppSnackBar.show(context, message: 'Added to cellar! 🍷');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: AppColors.darkBlue, size: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeOneBottle(BuildContext context, WineModel wine) async {
    final cubit = context.read<MainCubit>();
    final spots = await cubit.getOccupiedSpots(wine.id);
    if (!context.mounted) return;

    Map<String, dynamic>? result;

    if (spots.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove bottle?'),
          content: const Text('This bottle will be removed from your cellar.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      result = {'removedCount': 1};
    } else {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StorageLocationDialog(wine: wine, removeMode: true),
      );
    }

    if (result == null || !context.mounted) return;
    final removedCount = result['removedCount'] as int? ?? 0;
    if (removedCount <= 0) return;

    final newQty = wine.quantity - removedCount;
    if (newQty <= 0) {
      cubit.deleteWine(wine.id);
      return;
    }

    final existing = wine.bottles?.isNotEmpty == true
        ? List<WineBottle>.from(wine.bottles!)
        : [WineBottle(id: '${wine.id}_default', wineId: wine.id, bottleSize: '750ml', quantity: wine.quantity)];
    final sorted = List<WineBottle>.from(existing)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final newQtyById = {for (var b in existing) b.id: b.quantity};
    var remaining = removedCount;
    for (final b in sorted) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0, b.quantity);
      newQtyById[b.id] = b.quantity - take;
      remaining -= take;
    }
    final newBottles = existing
        .map((b) => b.copyWith(quantity: newQtyById[b.id]!))
        .where((b) => b.quantity > 0)
        .toList();

    if (newBottles.isEmpty) {
      cubit.deleteWine(wine.id);
    } else {
      cubit.updateBottleSizes(wine, newBottles, skipPositionUpdate: true);
    }
  }
}
