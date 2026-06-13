import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/bottle_wine.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_state.dart';
import 'package:wine_cellar/feature/search_page/presentation/page/wine_detail_page.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/repository/wine_repository.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_state.dart';

@RoutePage()
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);

    return BlocProvider(
      create: (_) => getIt<MainCubit>()..loadWines(),
      child: Scaffold(
        backgroundColor: AppColors.baseWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Wishlist', style: AppTextStyles.h1),
          centerTitle: screenWidth <= 600,
        ),
        body: BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, state) {
            if (state is WishlistInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.darkBlue),
              );
            }

            if (state is WishlistLoaded && state.wines.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: AppColors.lightBlue.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty.\nFind wines in the catalog and save them here!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            if (state is WishlistLoaded) {
              return GridView.builder(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.6,
                ),
                itemCount: state.wines.length,
                itemBuilder: (context, index) => _WishlistCard(wine: state.wines[index]),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WineModel wine;

  const _WishlistCard({required this.wine});

  @override
  Widget build(BuildContext context) {
    final subtitle = [wine.region, wine.vintage?.toString()]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: () => context.router.push(WineDetailRoute(wine: wine)),
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
                              errorBuilder: (_, __, ___) =>
                                  Center(child: AbstractWineBottle(type: wine.type, size: 110)),
                            )
                          : Center(child: AbstractWineBottle(type: wine.type, size: 110)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => context.read<WishlistCubit>().toggle(wine),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bookmark, color: AppColors.darkBlue, size: 18),
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
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 10),
                  _AddToCellarButton(wine: wine),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToCellarButton extends StatelessWidget {
  final WineModel wine;

  const _AddToCellarButton({required this.wine});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        final inCellar = state is MainLoaded && state.wines.any((w) => w.id == wine.id);

        if (inCellar) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: AppColors.darkBlue),
                const SizedBox(width: 4),
                Text(
                  'In Cellar',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () => _addToCellar(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Add to Cellar',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCellar(BuildContext context) async {
    WineModel wineDetails;
    try {
      wineDetails = await getIt<WineRepository>().getWineDetails(wine.id);
    } catch (_) {
      wineDetails = wine;
    }
    if (!context.mounted) return;

    final picked = await showDialog<({String bottleSize, int quantity})>(
      context: context,
      builder: (ctx) => const BottleSizeQuantityPickerDialog(),
    );
    if (picked == null || !context.mounted) return;

    final bottles = [
      WineBottle(
        id: '${wineDetails.id}_${DateTime.now().microsecondsSinceEpoch}',
        wineId: wineDetails.id,
        bottleSize: picked.bottleSize,
        quantity: picked.quantity,
      ),
    ];

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StorageLocationDialog(wine: wineDetails.copyWith(quantity: picked.quantity)),
    );
    if (res == null || !context.mounted) return;

    final loc = res['location'] as String;
    final qty = res['quantity'] as int;
    context.read<MainCubit>().saveWine(
      wineDetails.copyWith(cellarLocation: loc, quantity: qty, bottles: bottles),
    );
    context.read<WishlistCubit>().remove(wine.id);
  }
}
