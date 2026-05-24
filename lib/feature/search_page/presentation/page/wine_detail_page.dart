import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_wine/core/colors/app_colors.dart';
import 'package:home_wine/core/dependencies/get_it.dart';
import 'package:home_wine/core/router/app_router.dart';
import 'package:home_wine/core/style/app_text_style.dart';
import 'package:home_wine/core/widget/app_snackbar.dart';
import 'package:home_wine/core/widget/bottle_wine.dart';
import 'package:home_wine/core/widget/button.dart';
import 'package:home_wine/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:home_wine/feature/main_page/presentation/cubit/main_state.dart';
import 'package:home_wine/feature/profile_page/data/repository/profile_repository.dart';
import 'package:home_wine/feature/profile_page/data/repository/storage_model.dart';
import 'package:home_wine/feature/wine/data/models/purchase_record.dart';
import 'package:home_wine/feature/wine/data/models/wine_bottle.dart';
import 'package:home_wine/feature/wine/data/models/wine_model.dart';
import 'package:home_wine/feature/wine/data/repository/wine_repository.dart';
import 'package:home_wine/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';
import 'package:home_wine/feature/wishlist_page/presentation/cubit/wishlist_state.dart';

@RoutePage()
class WineDetailPage extends StatefulWidget {
  final WineModel? wine;

  const WineDetailPage({super.key, this.wine});

  @override
  State<WineDetailPage> createState() => _WineDetailPageState();
}

class _WineDetailPageState extends State<WineDetailPage> {
  late Future<WineModel> _wineFuture;
  late Future<List<PurchaseRecord>> _purchaseHistoryFuture;
  bool _purchaseHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _wineFuture = _resolveWineDetails();
    _purchaseHistoryFuture = _loadPurchaseHistory();
  }

  Future<WineModel> _resolveWineDetails() async {
    if (widget.wine == null) throw Exception('No wine provided');

    final savedWines = await getIt<MainRepository>().getLocalWines();
    final cellarWine = savedWines.where((w) => w.id == widget.wine!.id).firstOrNull;

    if (cellarWine != null) return cellarWine;

    return getIt<WineRepository>().getWineDetails(widget.wine!.id);
  }

  Future<List<PurchaseRecord>> _loadPurchaseHistory() async {
    if (widget.wine == null) return [];
    return getIt<MainRepository>().getPurchaseHistory(widget.wine!.id);
  }

  void _refreshPurchaseHistory() {
    setState(() {
      _purchaseHistoryFuture = _loadPurchaseHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    if (widget.wine == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replace(const DashboardRoute());
      });
      return const Scaffold(
        backgroundColor: AppColors.baseWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.darkBlue)),
      );
    }

    return BlocProvider(
      create: (context) => getIt<MainCubit>()..loadWines(),

      child: Builder(
        builder: (newContext) {
          return FutureBuilder<WineModel>(
            future: _wineFuture,
            builder: (context, snapshot) {
              final fullWine = snapshot.data ?? widget.wine!;
              final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

              return Scaffold(
                backgroundColor: AppColors.baseWhite,
                appBar: isDesktop
                    ? AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        iconTheme: const IconThemeData(color: AppColors.darkBlue),
                      )
                    : null,
                body: isDesktop
                    ? _buildDesktopLayout(fullWine, isLoading)
                    : _buildMobileLayout(fullWine, isLoading),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(WineModel wine, bool isLoading) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: AppColors.lightBlue.withOpacity(0.05),
            ),
            child: Center(
              child: Hero(
                tag: 'bottle_${wine.id}',
                child: wine.imageUrl != null && wine.imageUrl!.isNotEmpty
                    ? Image.network(
                        wine.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return AbstractWineBottle(type: wine.type, size: 300);
                        },
                      )
                    : AbstractWineBottle(type: wine.type, size: 300),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 80, top: 40, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfo(wine),
                const SizedBox(height: 32),
                _buildCellarControls(wine),
                const SizedBox(height: 48),
                _buildDetailedContent(wine, isLoading),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(WineModel wine, bool isLoading) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(wine),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfo(wine),
                const SizedBox(height: 32),
                _buildDetailedContent(wine, isLoading),
                const SizedBox(height: 32),
                SafeArea(top: false, child: _buildCellarControls(wine)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(WineModel wine) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.baseWhite,
      iconTheme: const IconThemeData(color: AppColors.darkBlue),
      flexibleSpace: FlexibleSpaceBar(
        background: wine.imageUrl != null && wine.imageUrl!.isNotEmpty
            ? Image.network(
                wine.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.lightBlue.withOpacity(0.05),
                    child: Center(child: AbstractWineBottle(type: wine.type, size: 200)),
                  );
                },
              )
            : Container(
                color: AppColors.lightBlue.withOpacity(0.05),
                child: Center(child: AbstractWineBottle(type: wine.type, size: 200)),
              ),
      ),
    );
  }

  Widget _buildMainInfo(WineModel wine) {
    final location =
        '${wine.region ?? ""}${wine.region != null && wine.country != null ? ", " : ""}${wine.country ?? ""}'
            .trim();
    final vintage = wine.vintage;
    final hasVintage = vintage != null && vintage > 0;
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        WineModel? cellarWine;
        if (state is MainLoaded) {
          cellarWine = state.wines.where((w) => w.id == wine.id).firstOrNull;
        }

        final isInCellar = cellarWine != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wine.name, style: AppTextStyles.h1.copyWith(fontSize: 22)),
                      const SizedBox(height: 8),
                      if (wine.winery != null && wine.winery!.isNotEmpty) ...[
                        Text(
                          wine.winery!,
                          style: AppTextStyles.body.copyWith(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        location.isNotEmpty ? location : 'Location unknown',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 18),
                      ),
                      if (hasVintage) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Year: $vintage',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (wine.averageRating != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.darkBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    wine.averageRating!.toStringAsFixed(1),
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkBlue,
                                    ),
                                  ),
                                  if (wine.ratingsCount != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${wine.ratingsCount})',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                BlocBuilder<WishlistCubit, WishlistState>(
                  builder: (context, wishState) {
                    final wishlisted = context.read<WishlistCubit>().isWishlisted(wine.id);
                    return IconButton(
                      icon: Icon(
                        wishlisted ? Icons.bookmark : Icons.bookmark_border,
                        color: AppColors.darkBlue,
                      ),
                      onPressed: () => context.read<WishlistCubit>().toggle(wine),
                    );
                  },
                ),
                if (isInCellar)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.darkBlue),
                    onPressed: () => _showEditWineDialog(context, wine),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedContent(WineModel wine, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: LinearProgressIndicator(color: AppColors.darkBlue),
          ),
        if (wine.description?.isNotEmpty == true) ...[
          Text('Description', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text(
            wine.description!,
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),
        ],

        if (wine.grapes != null && wine.grapes!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Grapes', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wine.grapes!.map((g) => Chip(
              label: Text(g, style: AppTextStyles.caption.copyWith(color: AppColors.darkBlue)),
              backgroundColor: AppColors.lightBlue.withOpacity(0.15),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          ),
        ],

        if (wine.scores != null && wine.scores!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Scores', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          ...wine.scores!.map((s) => _ScoreTile(score: s)),
        ],

        if (wine.notice != null && wine.notice!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('My Notice', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBlue.withOpacity(0.1)),
            ),
            child: Text(
              wine.notice!,
              style: AppTextStyles.body.copyWith(height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
        ],

        if (wine.prices != null && wine.prices!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Shop offers', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          ...wine.prices!.map((p) => _PriceTile(price: p)),
        ],
        if (wine.foodPairings != null && wine.foodPairings!.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Perfect pairing with:', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: wine.foodPairings!.map((food) => _buildFoodChip(food)).toList(),
          ),
        ],
        const SizedBox(height: 32),
        _buildPurchaseHistorySection(wine),
      ],
    );
  }

  Widget _buildPurchaseHistorySection(WineModel wine) {
    return FutureBuilder<List<PurchaseRecord>>(
      future: _purchaseHistoryFuture,
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _purchaseHistoryExpanded = !_purchaseHistoryExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Expanded(child: Text('Purchase History', style: AppTextStyles.h2)),
                  TextButton.icon(
                    onPressed: () => _showLogPurchaseDialog(context, wine),
                    icon: const Icon(Icons.add, size: 18, color: AppColors.darkBlue),
                    label: Text('Log', style: AppTextStyles.body.copyWith(color: AppColors.darkBlue)),
                  ),
                  Icon(
                    _purchaseHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.darkBlue,
                  ),
                ],
              ),
            ),
            if (_purchaseHistoryExpanded) ...[
              const SizedBox(height: 12),
              if (records.isEmpty)
                Text(
                  'No purchases logged yet.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                )
              else
                ...records.map((r) => _buildPurchaseRecordTile(r)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPurchaseRecordTile(PurchaseRecord record) {
    final dateStr = '${record.purchasedAt.day.toString().padLeft(2, '0')} '
        '${_monthName(record.purchasedAt.month)} '
        '${record.purchasedAt.year}';

    final sizeQty = record.bottleSize != null
        ? '${record.bottleSize} × ${record.quantity}'
        : '× ${record.quantity}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record.price.toStringAsFixed(2)} ${record.currency}',
                      style: AppTextStyles.h2.copyWith(fontSize: 16, color: AppColors.darkBlue),
                    ),
                    const SizedBox(width: 8),
                    Text(sizeQty, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    dateStr,
                    if (record.shopName != null && record.shopName!.isNotEmpty) record.shopName!,
                  ].join(' · '),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => _confirmDeletePurchaseRecord(record),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _confirmDeletePurchaseRecord(PurchaseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete record?'),
        content: const Text('This purchase record will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await getIt<MainRepository>().deletePurchaseRecord(record.id);
      _refreshPurchaseHistory();
    }
  }

  Future<void> _showLogPurchaseDialog(BuildContext context, WineModel wine) async {
    final record = await showDialog<PurchaseRecord>(
      context: context,
      builder: (ctx) => _LogPurchaseDialog(wineId: wine.id, existingSizes: _effectiveBottles(wine).map((b) => b.bottleSize).toList()),
    );
    if (record != null && mounted) {
      await getIt<MainRepository>().savePurchaseRecord(record);
      _refreshPurchaseHistory();
    }
  }

  Widget _buildFoodChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.1)),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.darkBlue)),
    );
  }

  List<WineBottle> _effectiveBottles(WineModel wine) {
    if (wine.bottles != null && wine.bottles!.isNotEmpty) return wine.bottles!;
    if (wine.quantity > 0) {
      return [WineBottle(id: '${wine.id}_default', wineId: wine.id, bottleSize: '750ml', quantity: wine.quantity)];
    }
    return [];
  }

  Widget _buildCellarControls(WineModel wine) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {

        if (state is MainLoading || state is MainInitial) {
          return Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlue),
              ),
            ),
          );
        }

        WineModel? cellarWine;
        if (state is MainLoaded) {
          cellarWine = state.wines.where((w) => w.id == wine.id).firstOrNull;
        }

        if (cellarWine != null) {
          final bottles = _effectiveBottles(cellarWine);
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('In Your Cellar', style: AppTextStyles.h2),
                    TextButton.icon(
                      onPressed: () => _showAddSizeDialog(context, cellarWine!),
                      icon: const Icon(Icons.add, size: 18, color: AppColors.darkBlue),
                      label: Text('Add size', style: AppTextStyles.caption.copyWith(color: AppColors.darkBlue)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                ...bottles.map((bottle) => _buildBottleSizeRow(context, cellarWine!, bottle)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                _buildLocationPicker(context, cellarWine),
              ],
            ),
          );
        }

        return AppButton(
          text: 'Add to Cellar',
          onPressed: () async {
            final picked = await showDialog<({String bottleSize, int quantity})>(
              context: context,
              builder: (ctx) => const BottleSizeQuantityPickerDialog(),
            );
            if (picked == null || !context.mounted) return;

            final res = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: picked.quantity)),
            );
            if (res != null && context.mounted) {
              final loc = res['location'] as String;
              final qty = res['quantity'] as int;
              final bottles = [
                WineBottle(
                  id: '${wine.id}_${DateTime.now().microsecondsSinceEpoch}',
                  wineId: wine.id,
                  bottleSize: picked.bottleSize,
                  quantity: qty,
                ),
              ];
              await context.read<MainCubit>().saveWine(
                wine.copyWith(cellarLocation: loc, quantity: qty, bottles: bottles),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildBottleSizeRow(BuildContext context, WineModel wine, WineBottle bottle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(bottle.bottleSize, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
          _buildSizeQuantityPicker(context, wine, bottle),
        ],
      ),
    );
  }

  Widget _buildSizeQuantityPicker(BuildContext context, WineModel wine, WineBottle bottle) {
    final bottles = _effectiveBottles(wine);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.darkBlue),
            onPressed: () async {
              if (bottle.quantity <= 1) {
                final confirmed = await _confirmRemoveSize(context, bottle.bottleSize);
                if (!confirmed || !context.mounted) return;
                final newBottles = bottles.where((b) => b.id != bottle.id).toList();
                if (newBottles.isEmpty) {
                  await context.read<MainCubit>().deleteWine(wine.id);
                } else {
                  await context.read<MainCubit>().updateBottleSizes(wine, newBottles);
                }
              } else {
                final newBottles = bottles
                    .map((b) => b.id == bottle.id ? b.copyWith(quantity: b.quantity - 1) : b)
                    .toList();
                await context.read<MainCubit>().updateBottleSizes(wine, newBottles);
              }
            },
          ),
          Text('${bottle.quantity}', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.darkBlue),
            onPressed: () async {
              final addQty = await showDialog<int>(
                context: context,
                builder: (ctx) => const _AddQuantityDialog(),
              );
              if (addQty == null || addQty <= 0 || !context.mounted) return;
              final res = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: wine.quantity + addQty)),
              );
              if (res == null || !context.mounted) return;
              final newBottles = bottles
                  .map((b) => b.id == bottle.id ? b.copyWith(quantity: b.quantity + addQty) : b)
                  .toList();
              await context.read<MainCubit>().updateBottleSizes(wine, newBottles);
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmRemoveSize(BuildContext context, String bottleSize) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove size?'),
        content: Text('Remove $bottleSize from your cellar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showAddSizeDialog(BuildContext context, WineModel wine) async {
    final existingSizes = _effectiveBottles(wine).map((b) => b.bottleSize).toSet();
    final result = await showDialog<({String bottleSize, int quantity})>(
      context: context,
      builder: (ctx) => _AddSizeDialog(existingSizes: existingSizes),
    );
    if (result == null || !context.mounted) return;

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: wine.quantity + result.quantity)),
    );
    if (res == null || !context.mounted) return;

    final newBottle = WineBottle(
      id: '${wine.id}_${result.bottleSize}_${DateTime.now().microsecondsSinceEpoch}',
      wineId: wine.id,
      bottleSize: result.bottleSize,
      quantity: result.quantity,
    );
    final bottles = _effectiveBottles(wine);
    final existing = bottles.where((b) => b.bottleSize == result.bottleSize).firstOrNull;
    List<WineBottle> newBottles;
    if (existing != null) {
      newBottles = bottles
          .map((b) => b.bottleSize == result.bottleSize ? b.copyWith(quantity: b.quantity + result.quantity) : b)
          .toList();
    } else {
      newBottles = [...bottles, newBottle];
    }
    await context.read<MainCubit>().updateBottleSizes(wine, newBottles);
  }

  Widget _buildLocationPicker(BuildContext context, WineModel wine) {
    final hasLocation = wine.cellarLocation?.isNotEmpty == true;

    final allLocations = hasLocation ? wine.cellarLocation!.split(' ; ') : ['No location set'];

    const List<IconData> hierarchyIcons = [
      Icons.door_sliding_outlined,
      Icons.reorder_rounded,
      Icons.wine_bar_rounded,
    ];

    return InkWell(
      onTap: () => _showLocationDialog(context, wine),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Location', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
            ],
          ),

          const SizedBox(height: 12),

          Column(
            children: List.generate(allLocations.length, (locIndex) {
              if (!hasLocation) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
                  ),
                  child: Text(
                    allLocations[locIndex],
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              final parts = allLocations[locIndex].split(' > ');

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.baseWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBlue.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allLocations.length > 1) ...[
                      Text(
                        'Location ${locIndex + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: List.generate(parts.length, (partIndex) {
                            final isLast = partIndex == parts.length - 1;
                            final icon = partIndex < hierarchyIcons.length
                                ? hierarchyIcons[partIndex]
                                : hierarchyIcons.last;

                            return ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLast
                                            ? AppColors.darkBlue
                                            : AppColors.lightBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 14,
                                            color: isLast ? AppColors.baseWhite : AppColors.darkBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              parts[partIndex].trim(),
                                              style: AppTextStyles.caption.copyWith(
                                                color: isLast ? AppColors.baseWhite : AppColors.darkBlue,
                                                fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isLast) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationDialog(BuildContext context, WineModel cellarWine) async {
    final mainCubit = context.read<MainCubit>();

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StorageLocationDialog(wine: cellarWine),
    );

    if (res != null && context.mounted) {
      final loc = res['location'] as String;
      final qty = res['quantity'] as int;
      await mainCubit.saveWine(cellarWine.copyWith(cellarLocation: loc, quantity: qty));
    }
  }

  Future<void> _showEditWineDialog(BuildContext context, WineModel wine) async {
    final mainCubit = context.read<MainCubit>();
    final result = await showDialog<WineModel>(
      context: context,
      builder: (ctx) => EditWineDialog(wine: wine),
    );

    if (result != null && context.mounted) {
      await mainCubit.saveWine(result);
      setState(() {
        _wineFuture = Future.value(result);
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottle size + quantity picker (used before "Add to Cellar" and from catalog)
// ─────────────────────────────────────────────────────────────────────────────

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
                color: AppColors.lightBlue.withOpacity(0.1),
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
      backgroundColor: AppColors.lightBlue.withOpacity(0.1),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.darkBlue,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add quantity dialog (used on "+" next to an existing bottle size)
// ─────────────────────────────────────────────────────────────────────────────

class _AddQuantityDialog extends StatefulWidget {
  const _AddQuantityDialog();

  @override
  State<_AddQuantityDialog> createState() => _AddQuantityDialogState();
}

class _AddQuantityDialogState extends State<_AddQuantityDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('How many to add?'),
      content: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withOpacity(0.1),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, _quantity),
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add size dialog (for existing cellar wine)
// ─────────────────────────────────────────────────────────────────────────────

class _AddSizeDialog extends StatefulWidget {
  final Set<String> existingSizes;
  const _AddSizeDialog({required this.existingSizes});

  @override
  State<_AddSizeDialog> createState() => _AddSizeDialogState();
}

class _AddSizeDialogState extends State<_AddSizeDialog> {
  String _selected = '';
  bool _isCustom = false;
  int _quantity = 1;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = WineBottle.standardSizes.firstWhere(
      (s) => !widget.existingSizes.contains(s),
      orElse: () => WineBottle.standardSizes.first,
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Add Bottle Size'),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
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
          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.lightBlue.withOpacity(0.1),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.darkBlue,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log purchase dialog
// ─────────────────────────────────────────────────────────────────────────────

class _LogPurchaseDialog extends StatefulWidget {
  final String wineId;
  final List<String> existingSizes;
  const _LogPurchaseDialog({required this.wineId, required this.existingSizes});

  @override
  State<_LogPurchaseDialog> createState() => _LogPurchaseDialogState();
}

class _LogPurchaseDialogState extends State<_LogPurchaseDialog> {
  bool _priceError = false;
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: '€');
  final _shopNameController = TextEditingController();
  final _customSizeController = TextEditingController();
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
  }

  @override
  void dispose() {
    _priceController.dispose();
    _currencyController.dispose();
    _shopNameController.dispose();
    _customSizeController.dispose();
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

            // Price + currency
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

            // Quantity
            Text('Quantity', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
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

            // Date
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

            // Bottle size (optional)
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
                  backgroundColor: AppColors.lightBlue.withOpacity(0.1),
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
                  backgroundColor: AppColors.lightBlue.withOpacity(0.1),
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
                  backgroundColor: AppColors.lightBlue.withOpacity(0.1),
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

            _field('Store', _shopNameController, 'e.g. Wine Spectator Shop'),
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
                      shopLocation: null,
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

  Widget _field(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text, bool hasError = false}) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final errorBorder = OutlineInputBorder(
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
            border: hasError ? errorBorder : border,
            enabledBorder: hasError ? errorBorder : border,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
                  ),
            contentPadding: const EdgeInsets.all(12),
            errorText: hasError ? 'Required' : null,
            errorStyle: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit wine dialog (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price tile (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _PriceTile extends StatelessWidget {
  final WinePrice price;
  const _PriceTile({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(price.merchant ?? 'Merchant', style: AppTextStyles.body),
          Text(
            '${price.price} ${price.currency}',
            style: AppTextStyles.h2.copyWith(color: AppColors.darkBlue, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final WineScore score;
  const _ScoreTile({required this.score});

  @override
  Widget build(BuildContext context) {
    final displayScore = (score.scoreText?.isNotEmpty == true)
        ? score.scoreText!
        : score.score?.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          if (displayScore != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayScore,
                style: AppTextStyles.h2.copyWith(fontSize: 16, color: AppColors.darkBlue),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              score.reviewer.isNotEmpty ? score.reviewer : 'Unknown reviewer',
              style: AppTextStyles.body,
            ),
          ),
          if (score.reviewDate != null && score.reviewDate!.isNotEmpty)
            Text(
              score.reviewDate!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Storage location dialog (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class StorageLocationDialog extends StatefulWidget {
  final WineModel wine;

  const StorageLocationDialog({super.key, required this.wine});

  @override
  State<StorageLocationDialog> createState() => _StorageLocationDialogState();
}

class _StorageLocationDialogState extends State<StorageLocationDialog> {
  static const String _unassignedCabinetId = '__unassigned__';
  final CabinetModel _unassignedCabinet = CabinetModel(
    id: _unassignedCabinetId,
    name: 'Unassigned',
    shelves: const [],
  );
  List<CabinetModel> _cabinets = [];
  bool _isLoading = true;

  CabinetModel? _selectedCabinet;
  ShelfModel? _selectedShelf;
  final Set<String> _selectedSpotIds = {};
  final Set<String> _initialSelectedSpotIds = {};

  @override
  void initState() {
    super.initState();
    _loadCabinets();
  }

  Future<void> _loadCabinets() async {
    final repo = getIt<ProfileRepository>();
    final cabinets = await repo.getStorageLocations();
    if (mounted) {
      setState(() {
        _cabinets = cabinets;
        _isLoading = false;

        for (var cab in _cabinets) {
          for (var shelf in cab.shelves) {
            for (var pos in shelf.positions) {
              if (pos.wineId == widget.wine.id) {
                _selectedCabinet ??= cab;
                _selectedShelf ??= shelf;
                _selectedSpotIds.add(pos.id);
                _initialSelectedSpotIds.add(pos.id);
              }
            }
          }
        }

        _restoreSelectedSpotsFromWineLocation();
        _initialSelectedSpotIds.addAll(_selectedSpotIds);

        if (_selectedCabinet == null && (widget.wine.cellarLocation?.contains('Unassigned') ?? false)) {
          _selectedCabinet = _unassignedCabinet;
        }
      });
    }
  }

  void _restoreSelectedSpotsFromWineLocation() {
    final location = widget.wine.cellarLocation;
    if (location == null || location.isEmpty) return;

    final entries = location
        .split(' ; ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'Unassigned' && e.contains('Spot '))
        .toList();

    for (final entry in entries) {
      final parts = entry.split(' > ');
      if (parts.length < 3) continue;

      final cabinetName = parts[0].trim();
      final shelfName = parts[1].trim();
      final spotPart = parts[2].replaceFirst('Spot ', '').trim();
      final spotIndexes = spotPart
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();

      if (spotIndexes.isEmpty) continue;

      final cabinet = _cabinets.where((c) => c.name == cabinetName).firstOrNull;
      if (cabinet == null) continue;

      final shelf = cabinet.shelves.where((s) => s.name == shelfName).firstOrNull;
      if (shelf == null) continue;

      for (final pos in shelf.positions) {
        if (spotIndexes.contains(pos.index)) {
          _selectedSpotIds.add(pos.id);
        }
      }

      _selectedCabinet ??= cabinet;
      _selectedShelf ??= shelf;
    }
  }

  Future<void> _saveLocation() async {
    final bool isUnassignedSelected = _selectedCabinet?.id == _unassignedCabinetId;
    final totalQuantity = widget.wine.quantity;

    if (!isUnassignedSelected && _selectedSpotIds.length > totalQuantity) {
      AppSnackBar.show(
        context,
        message: 'You can select up to $totalQuantity spot(s) for this wine.',
        isError: true,
      );
      return;
    }

    final removedSpots = _initialSelectedSpotIds.difference(_selectedSpotIds);
    final addedSpots = _selectedSpotIds.difference(_initialSelectedSpotIds);
    final hasChanges = removedSpots.isNotEmpty || addedSpots.isNotEmpty;

    if (hasChanges) {
      final confirmed = await _confirmLocationChange(
        removedCount: removedSpots.length,
        addedCount: addedSpots.length,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _isLoading = true);

    final repo = getIt<ProfileRepository>();
    List<String> locationParts = [];

    for (var cab in _cabinets) {
      bool cabinetNeedsUpdate = false;

      final updatedShelves = cab.shelves.map((shelf) {
        bool shelfNeedsUpdate = false;
        List<int> shelfSpotIndexes = [];

        final updatedPositions = shelf.positions.map((pos) {
          final shouldBeSelected = _selectedSpotIds.contains(pos.id);
          final isCurrentlySelected = pos.wineId == widget.wine.id;

          if (shouldBeSelected) {
            shelfSpotIndexes.add(pos.index);
            if (!isCurrentlySelected) {
              shelfNeedsUpdate = true;
              return BottlePositionModel(id: pos.id, index: pos.index, wineId: widget.wine.id);
            }
          } else if (isCurrentlySelected) {
            shelfNeedsUpdate = true;
            return BottlePositionModel(id: pos.id, index: pos.index, wineId: null);
          }
          return pos;
        }).toList();

        if (shelfSpotIndexes.isNotEmpty) {
          shelfSpotIndexes.sort();
          locationParts.add('${cab.name} > ${shelf.name} > Spot ${shelfSpotIndexes.join(', ')}');
        }

        if (shelfNeedsUpdate) cabinetNeedsUpdate = true;
        return ShelfModel(id: shelf.id, name: shelf.name, positions: updatedPositions);
      }).toList();

      if (cabinetNeedsUpdate) {
        await repo.saveCabinet(CabinetModel(id: cab.id, name: cab.name, shelves: updatedShelves));
      }
    }

    if (mounted) {
      final selectedSpotsCount = _selectedSpotIds.length;
      final hasUnassignedRemainder = !isUnassignedSelected && selectedSpotsCount < totalQuantity;

      if (hasUnassignedRemainder) {
        locationParts.add('Unassigned');
      }

      final newLocationString = isUnassignedSelected
          ? (locationParts.isEmpty ? 'Unassigned' : '${locationParts.join(' ; ')} ; Unassigned')
          : locationParts.join(' ; ');

      final newQuantity = totalQuantity;
      Navigator.pop(context, {'location': newLocationString, 'quantity': newQuantity});
    }
  }

  Future<bool> _confirmLocationChange({
    required int removedCount,
    required int addedCount,
  }) async {
    final int affectedCount = removedCount > 0 ? removedCount : addedCount;
    final bottleWord = affectedCount == 1 ? 'bottle' : 'bottles';

    final bool removeOnly = removedCount > 0 && addedCount == 0;
    final message = removeOnly
        ? 'The selected $bottleWord will be moved to Unassigned.'
        : 'The selected $bottleWord location will be updated.';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm location change'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(color: AppColors.darkBlue)),
        ),
      );
    }

    if (_cabinets.isEmpty) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Storage Location'),
        content: const Text(
          'No storage available. Please create a storage in your Profile > Manage Storage.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _selectedSpotIds.clear();
              _saveLocation();
            },
            child: const Text('Add Unassigned'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Select Location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<CabinetModel>(
              initialValue: _selectedCabinet,
              isExpanded: true,
              hint: const Text('Select Storage'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                DropdownMenuItem(value: _unassignedCabinet, child: const Text('Unassigned')),
                ..._cabinets.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
              ],
              onChanged: (val) => setState(() {
                if (_selectedCabinet != val) {
                  _selectedCabinet = val;
                  _selectedShelf = null;
                }
              }),
            ),
            const SizedBox(height: 16),
            if (_selectedCabinet?.id == _unassignedCabinetId)
              Text(
                'All selected bottles will be saved to Unassigned.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              )
            else if (_selectedCabinet != null && _selectedCabinet!.shelves.isNotEmpty)
              DropdownButtonFormField<ShelfModel>(
                initialValue: _selectedShelf,
                isExpanded: true,
                hint: const Text('Select Shelf'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _selectedCabinet!.shelves
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => setState(() {
                  if (_selectedShelf != val) {
                    _selectedShelf = val;
                  }
                }),
              )
            else if (_selectedCabinet != null)
              const Text('No shelves in this storage.', style: TextStyle(color: AppColors.error)),
            if (_selectedShelf != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Spots (Tap to select multiple)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedShelf!.positions.map((pos) {
                  final isSelected = _selectedSpotIds.contains(pos.id);
                  final isOccupied = pos.wineId != null && pos.wineId != widget.wine.id;
                  final reachedLimit =
                      !isSelected && _selectedSpotIds.length >= widget.wine.quantity;
                  final isDisabled = isOccupied || reachedLimit;

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedSpotIds.remove(pos.id);
                              } else {
                                _selectedSpotIds.add(pos.id);
                              }
                            });
                          },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey.shade300
                            : (isSelected ? AppColors.darkBlue : AppColors.lightBlue.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.darkBlue : Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          '${pos.index}',
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.grey.shade500
                                : (isSelected ? Colors.white : AppColors.darkBlue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Selected: ${_selectedSpotIds.length}/${widget.wine.quantity}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: _saveLocation,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
