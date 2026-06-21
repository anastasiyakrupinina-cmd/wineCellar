import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/bottle_wine.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_cubit.dart';
import 'package:wine_cellar/feature/main_page/presentation/cubit/main_state.dart';
import 'package:wine_cellar/feature/search_page/presentation/widget/add_size_dialog.dart';
import 'package:wine_cellar/feature/search_page/presentation/widget/edit_wine_dialog.dart';
import 'package:wine_cellar/feature/search_page/presentation/widget/log_purchase_dialog.dart';
import 'package:wine_cellar/feature/search_page/presentation/widget/quantity_dialogs.dart';
import 'package:wine_cellar/feature/search_page/presentation/widget/wine_detail_tiles.dart';
import 'package:wine_cellar/feature/wine/data/models/purchase_record.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';
import 'package:wine_cellar/feature/wine/data/repository/wine_repository.dart';
import 'package:wine_cellar/feature/wine/presentation/widget/bottle_size_quantity_picker_dialog.dart';
import 'package:wine_cellar/feature/wine/presentation/widget/storage_location_dialog.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_cubit.dart';
import 'package:wine_cellar/feature/wishlist_page/presentation/cubit/wishlist_state.dart';

@RoutePage()
class WineDetailPage extends StatefulWidget {
  final WineModel? wine;
  final bool readOnly;

  const WineDetailPage({super.key, this.wine, this.readOnly = false});

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

    if (widget.readOnly) return widget.wine!;

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
              color: AppColors.lightBlue.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Hero(
                tag: 'bottle_${wine.id}',
                child: AbstractWineBottle(type: wine.type, size: 300),
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
                if (!widget.readOnly) _buildCellarControls(wine),
                SizedBox(height: widget.readOnly ? 0 : 48),
                _buildDetailedContent(wine, isLoading),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(WineModel wine, bool isLoading) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(wine),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainInfo(wine),
                      const SizedBox(height: 16),
                      _buildDetailedContent(wine, isLoading),
                      BlocBuilder<MainCubit, MainState>(
                        builder: (context, state) {
                          if (state is MainLoaded &&
                              state.wines.any((w) => w.id == wine.id)) {
                            return Column(
                              children: [
                                const SizedBox(height: 32),
                                SafeArea(top: false, child: _buildCellarControls(wine)),
                                const SizedBox(height: 32),
                              ],
                            );
                          }
                          return const SizedBox(height: 100);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.readOnly)
          BlocBuilder<MainCubit, MainState>(
            builder: (context, state) {
              if (state is MainLoading || state is MainInitial) {
                return const SizedBox(
                  height: 68,
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlue),
                    ),
                  ),
                );
              }
              if (state is MainLoaded && state.wines.any((w) => w.id == wine.id)) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _buildAddToCellarButton(context, wine),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddToCellarButton(BuildContext context, WineModel wine) {
    return AppButton(
      text: 'Add to Cellar',
      onPressed: () => _addToCellar(context, wine),
    );
  }

  Future<void> _addToCellar(BuildContext context, WineModel wine) async {
    final picked = await showDialog<({String bottleSize, int quantity})>(
      context: context,
      builder: (ctx) => const BottleSizeQuantityPickerDialog(),
    );
    if (picked == null || !context.mounted) return;

    final bottles = [
      WineBottle(
        id: '${wine.id}_${DateTime.now().microsecondsSinceEpoch}',
        wineId: wine.id,
        bottleSize: picked.bottleSize,
        quantity: picked.quantity,
      ),
    ];

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: picked.quantity), bottleSize: picked.bottleSize),
    );
    if (res != null && context.mounted) {
      final loc = res['location'] as String;
      final qty = res['quantity'] as int;
      await context.read<MainCubit>().saveWine(
        wine.copyWith(cellarLocation: loc, quantity: qty, bottles: bottles),
      );
    }
  }

  Widget _buildSliverAppBar(WineModel wine) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.baseWhite,
      iconTheme: const IconThemeData(color: AppColors.darkBlue),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
                color: AppColors.lightBlue.withValues(alpha: 0.05),
                child: Center(child: AbstractWineBottle(type: wine.type, size: 200)),
              ),
      ),
    );
  }

  Widget _buildMainInfo(WineModel wine) {
    final locationParts = [
      if (wine.region?.isNotEmpty == true) wine.region!,
      if (wine.country?.isNotEmpty == true) wine.country!,
    ];
    final location = locationParts.join(', ');
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
                      if (location.isNotEmpty)
                        Text(
                          location,
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

  static List<String>? _parsePairings(String? raw) {
    if (raw == null) return null;
    final list = jsonDecode(raw);
    if (list is! List) return null;
    return list.map((e) {
      if (e is Map) return e['food']?.toString() ?? '';
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
  }

  static List<WineScore>? _parseScores(String? raw) {
    if (raw == null) return null;
    final list = jsonDecode(raw);
    if (list is! List) return null;
    return list
        .map((e) => WineScore.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Widget _buildDetailedContent(WineModel wine, bool isLoading) {
    final pairings = wine.foodPairings ?? _parsePairings(wine.rawPairingsJson);
    final scores = wine.scores ?? _parseScores(wine.rawScoresJson);
    final sections = <Widget>[];

    if (wine.description?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Description', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        Text(wine.description!, style: AppTextStyles.body.copyWith(height: 1.6)),
      ]));
    }

    if (wine.grapes?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Grapes', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: wine.grapes!.map((g) => Chip(
            label: Text(g, style: AppTextStyles.caption.copyWith(color: AppColors.darkBlue)),
            backgroundColor: AppColors.lightBlue.withValues(alpha: 0.15),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
      ]));
    }

    if (scores?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Scores', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        ...scores!.map((s) => ScoreTile(score: s)),
      ]));
    }

    if (wine.notice?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Notice', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.1)),
          ),
          child: Text(wine.notice!, style: AppTextStyles.body.copyWith(height: 1.6, fontStyle: FontStyle.italic)),
        ),
      ]));
    }

    if (wine.prices?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Shop offers', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        ...wine.prices!.map((p) => PriceTile(price: p)),
      ]));
    }

    if (pairings?.isNotEmpty == true) {
      sections.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Perfect pairing with:', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: pairings!.map((food) => _buildFoodChip(food)).toList(),
        ),
      ]));
    }

    sections.add(_buildPurchaseHistorySection(wine));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(color: AppColors.darkBlue),
          ),
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 28),
          sections[i],
        ],
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
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.1)),
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
      builder: (ctx) => LogPurchaseDialog(wineId: wine.id, existingSizes: _effectiveBottles(wine).map((b) => b.bottleSize).toList()),
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
        color: AppColors.lightBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.1)),
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
              color: AppColors.lightBlue.withValues(alpha: 0.05),
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
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
          onPressed: () => _addToCellar(context, wine),
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
        color: AppColors.lightBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.darkBlue),
            onPressed: () async {
              final cubit = context.read<MainCubit>();
              final spots = await cubit.getOccupiedSpots(wine.id);
              if (!context.mounted) return;

              final sizeSpots = spots.where((s) => s.bottleSize == bottle.bottleSize).toList();
              final unassignedForSize = bottle.quantity - sizeSpots.length;

              Map<String, dynamic>? result;
              if (sizeSpots.isEmpty) {
                final confirmed = await _confirmRemoveSize(context, bottle.bottleSize);
                if (!confirmed || !context.mounted) return;
                result = {'removedCount': 1};
              } else if (unassignedForSize > 0) {
                final removeFromUnassigned = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Remove ${bottle.bottleSize}'),
                    content: const Text('Where would you like to remove the bottle from?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unassigned')),
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('From Storage')),
                    ],
                  ),
                );
                if (removeFromUnassigned == null || !context.mounted) return;
                if (removeFromUnassigned) {
                  final count = await showDialog<int>(
                    context: context,
                    builder: (ctx) => RemoveUnassignedDialog(max: unassignedForSize),
                  );
                  if (count == null || !context.mounted) return;
                  result = {'removedCount': count};
                } else {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (ctx) => StorageLocationDialog(
                      wine: wine,
                      removeMode: true,
                      maxRemovable: bottle.quantity,
                      bottleSize: bottle.bottleSize,
                    ),
                  );
                }
              } else {
                result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) => StorageLocationDialog(
                    wine: wine,
                    removeMode: true,
                    maxRemovable: bottle.quantity,
                    bottleSize: bottle.bottleSize,
                  ),
                );
              }

              if (result == null || !context.mounted) return;
              final removedCount = result['removedCount'] as int? ?? 0;
              if (removedCount <= 0) return;

              final newBottleQty = bottle.quantity - removedCount;
              final List<WineBottle> newBottles;
              if (newBottleQty <= 0) {
                newBottles = bottles.where((b) => b.id != bottle.id).toList();
              } else {
                newBottles = bottles
                    .map((b) => b.id == bottle.id ? b.copyWith(quantity: newBottleQty) : b)
                    .toList();
              }

              if (newBottles.isEmpty) {
                await cubit.deleteWine(wine.id);
              } else {
                await cubit.updateBottleSizes(wine, newBottles, skipPositionUpdate: true);
              }
            },
          ),
          Text('${bottle.quantity}', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.darkBlue),
            onPressed: () async {
              final addQty = await showDialog<int>(
                context: context,
                builder: (ctx) => const AddQuantityDialog(),
              );
              if (addQty == null || addQty <= 0 || !context.mounted) return;
              final res = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: wine.quantity + addQty), bottleSize: bottle.bottleSize, lockInitialSpots: true, maxNewSpots: addQty),
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
      builder: (ctx) => AddSizeDialog(existingSizes: existingSizes),
    );
    if (result == null || !context.mounted) return;

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StorageLocationDialog(wine: wine.copyWith(quantity: wine.quantity + result.quantity), bottleSize: result.bottleSize, lockInitialSpots: true, maxNewSpots: result.quantity),
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

    int assignedCount = 0;
    if (hasLocation) {
      for (final seg in allLocations) {
        if (seg.trim() == 'Unassigned') continue;
        final spotPart = seg.split(' > ').last.trim();
        if (spotPart.startsWith('Spot ')) {
          assignedCount += spotPart.replaceFirst('Spot ', '').split(',').length;
        }
      }
    }
    final unassignedCount = wine.quantity - assignedCount;

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
                    color: AppColors.lightBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.2)),
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
                  border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBlue.withValues(alpha: 0.03),
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
                                            : AppColors.lightBlue.withValues(alpha: 0.15),
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
                                              parts[partIndex].trim() == 'Unassigned'
                                                  ? 'Unassigned × $unassignedCount'
                                                  : parts[partIndex].trim(),
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
