import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/dependencies/get_it.dart';
import 'package:home_wine/core/router/app_router.dart';
import 'package:home_wine/core/style/app_text_style.dart';
import 'package:home_wine/core/widget/app_snackbar.dart';
import 'package:home_wine/core/widget/bottle_wine.dart';
import 'package:home_wine/core/widget/text_field.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_state.dart';
import 'package:home_wine/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:home_wine/feature/wine/data/repository/wine_repository.dart';
import 'package:home_wine/feature/wine/presentation/cubit/wine_search_cubit.dart';
import 'package:home_wine/feature/wine/presentation/cubit/wine_search_state.dart';

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
                      hint: 'Name, variety, region, or year...',
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
              color: AppColors.darkBlue.withOpacity(0.05),
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
                      color: AppColors.lightBlue.withOpacity(0.2),
                      child: wine.imageUrl != null && wine.imageUrl!.isNotEmpty
                          ? Image.network(
                              wine.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: AbstractWineBottle(type: wine.type, size: 110),
                                );
                              },
                            )
                          : Center(
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
                            color: AppColors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: AppColors.darkBlue, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () async {
                                  final confirmed = await _confirmQuantityAction(
                                    context,
                                    isIncrease: false,
                                    count: 1,
                                  );
                                  if (!confirmed || !context.mounted) return;
                                  context.read<MainCubit>().updateQuantity(cellarWine!, quantity - 1);
                                },
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
                                  final confirmed = await _confirmQuantityAction(
                                    context,
                                    isIncrease: true,
                                    count: 1,
                                  );
                                  if (!confirmed || !context.mounted) return;
                                  if (cellarWine!.cellarLocation != null &&
                                      cellarWine.cellarLocation!.isNotEmpty) {
                                    final res = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (ctx) => StorageLocationDialog(
                                        wine: cellarWine!.copyWith(quantity: quantity + 1),
                                      ),
                                    );
                                    if (res != null && context.mounted) {
                                      final loc = res['location'] as String;
                                      final qty = res['quantity'] as int;
                                      context.read<MainCubit>().saveWine(
                                        cellarWine.copyWith(cellarLocation: loc, quantity: qty),
                                      );
                                    }
                                  } else {
                                    context.read<MainCubit>().updateQuantity(cellarWine, quantity + 1);
                                  }
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

                          if (context.mounted) {
                            final res = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (ctx) => StorageLocationDialog(wine: wineToAdd.copyWith(quantity: 1)),
                            );
                            if (res != null && context.mounted) {
                              final loc = res['location'] as String;
                              final qty = res['quantity'] as int;
                              context.read<MainCubit>().saveWine(
                                wineToAdd.copyWith(cellarLocation: loc, quantity: qty),
                              );
                              AppSnackBar.show(context, message: 'Added to cellar! 🍷');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue.withOpacity(0.2),
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

  Future<bool> _confirmQuantityAction(
    BuildContext context, {
    required bool isIncrease,
    required int count,
  }) async {
    final noun = count > 1 ? 'bottles' : 'bottle';
    final message = isIncrease
        ? 'This $noun will be added to your collection.'
        : 'This $noun will be removed from your collection.';
    final actionText = isIncrease ? 'Add' : 'Remove';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isIncrease ? 'Add bottle?' : 'Remove bottle?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result == true;
  }
}
