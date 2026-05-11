import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/router/app_router.dart';
import 'package:home_wine/core/style/app_text_style.dart';
import 'package:home_wine/core/widget/bottle_wine.dart';
import 'package:home_wine/core/widget/text_field.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';

class MainWineList extends StatelessWidget {
  final TextEditingController searchController;
  final Map<String, Map<String, List<WineModel>>> groupedWines;
  final Map<String, int> totalWineCountById;
  final bool showCabinetView;
  final String? selectedCabinet;
  final Function(String?) onCabinetSelected;
  final Function(WineModel) onWineLongPress;

  const MainWineList({
    super.key,
    required this.searchController,
    required this.groupedWines,
    required this.totalWineCountById,
    required this.showCabinetView,
    this.selectedCabinet,
    required this.onCabinetSelected,
    required this.onWineLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: 120,
      onRefresh: () => context.read<MainCubit>().loadWines(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSearchField(),
          if (showCabinetView) ...[_buildCabinetNavigation(), _buildCabinetContent()] else _buildListView(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 16),
      sliver: SliverToBoxAdapter(
        child: AppTextField(
          label: 'Search',
          hint: 'Search by name or region...',
          controller: searchController,
          prefixIcon: Icons.search_rounded,
          suffixIcon: searchController.text.isNotEmpty ? Icons.close_rounded : null,
          onSuffixTap: () {
            searchController.clear();
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
      ),
    );
  }

  Widget _buildCabinetNavigation() {
    if (selectedCabinet == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      sliver: SliverToBoxAdapter(
        child: InkWell(
          
          borderRadius: BorderRadius.circular(8),
          onTap: () => onCabinetSelected(null),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), 
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18, 
                  color: AppColors.darkBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  'Back to Storage',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabinetContent() {
    if (groupedWines.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No wines found', style: AppTextStyles.body)),
      );
    }

    if (selectedCabinet == null) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final cabinet = groupedWines.keys.elementAt(index);
            final count = groupedWines[cabinet]!.values.fold<int>(
              0,
              (sum, list) => sum + list.fold(0, (s, w) => s + w.quantity),
            );
            return _buildCabinetGridCard(cabinet, count);
          }, childCount: groupedWines.length),
        ),
      );
    }

    
    final cabinetData = groupedWines[selectedCabinet];
    if (cabinetData == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabinetHeader(selectedCabinet!),
            ...cabinetData.entries.map((s) => _buildShelfSection(s.key, s.value, onWineLongPress)),
            const SizedBox(height: 20),
          ],
        );
      }, childCount: 1),
    );
  }

  Widget _buildListView() {
    if (groupedWines.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No wines found', style: AppTextStyles.body)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final cabinetEntry = groupedWines.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabinetHeader(cabinetEntry.key),
            ...cabinetEntry.value.entries.map((s) => _buildShelfSection(s.key, s.value, onWineLongPress)),
            const SizedBox(height: 20),
          ],
        );
      }, childCount: groupedWines.length),
    );
  }

  

  Widget _buildCabinetGridCard(String cabinet, int totalBottles) {
    return GestureDetector(
      onTap: () => onCabinetSelected(cabinet),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(
                cabinet == 'Unassigned' ? Icons.inventory_2_outlined : Icons.kitchen_outlined,
                size: 32,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cabinet,
              style: AppTextStyles.h2.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$totalBottles bottles',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabinetHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.kitchen_outlined, size: 28, color: AppColors.darkBlue),
          const SizedBox(width: 12),
          Text(name, style: AppTextStyles.h1.copyWith(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildShelfSection(String shelfName, List<WineModel> wines, Function(WineModel) onWineLongPress) {
    final int totalBottles = wines.fold(0, (sum, w) => sum + w.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shelfName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            child: Row(
              children: [
                Text(
                  shelfName,
                  style: AppTextStyles.h2.copyWith(fontSize: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalBottles',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _ShelfView(wines: wines, onWineLongPress: onWineLongPress, totalWineCountById: totalWineCountById),
        const SizedBox(height: 16),
      ],
    );
  }
}



class _ShelfView extends StatelessWidget {
  final List<WineModel> wines;
  final Function(WineModel) onWineLongPress;
  final Map<String, int> totalWineCountById;
  const _ShelfView({required this.wines, required this.onWineLongPress, required this.totalWineCountById});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: wines.length,
            itemBuilder: (context, index) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: SizedBox(
                    width: 100,
                    child: _ShelfBottle(
                      wine: wines[index],
                      index: index,
                      totalWineCount: totalWineCountById[wines[index].id] ?? wines[index].quantity,
                      onLongPress: () => onWineLongPress(wines[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfBottle extends StatelessWidget {
  final WineModel wine;
  final int index;
  final int totalWineCount;
  final VoidCallback? onLongPress;
  const _ShelfBottle({required this.wine, required this.totalWineCount, this.index = 0, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    
    
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () async {
        await context.router.push(WineDetailRoute(wine: wine));
        if (context.mounted) {
          context.read<MainCubit>().loadWines();
        }
      },
      child: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildBottleBadges(),
                const SizedBox(height: 8),
                Hero(
                  tag: 'bottle_${wine.id}_${wine.cellarLocation ?? index}',
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: wine.imageUrl != null
                        ? Image.network(
                            wine.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return AbstractWineBottle(type: wine.type, size: 90);
                            },
                          )
                        : AbstractWineBottle(type: wine.type, size: 90),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: Text(
                    wine.name,
                    style: AppTextStyles.body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 15, decoration: BoxDecoration(color: AppColors.lightBlue.withValues(alpha: 0.1))),
        ],
      ),
    );
  }

  Widget _buildBottleBadges() {
    String spotText = '';
    if (wine.cellarLocation != null && wine.cellarLocation!.contains('Spot ')) {
      spotText = wine.cellarLocation!.split('Spot ').last.trim();
    }

    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (spotText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Spot $spotText',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (spotText.isNotEmpty) const SizedBox(width: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(8)),
            child: Text(
              'x$totalWineCount',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
