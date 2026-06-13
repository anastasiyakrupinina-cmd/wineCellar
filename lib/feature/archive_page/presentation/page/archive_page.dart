import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/router/app_router.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/bottle_wine.dart';
import 'package:wine_cellar/feature/archive_page/data/repository/archive_repository.dart';
import 'package:wine_cellar/feature/archive_page/presentation/cubit/archive_cubit.dart';
import 'package:wine_cellar/feature/archive_page/presentation/cubit/archive_state.dart';

@RoutePage()
class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> with AutoRouteAwareStateMixin<ArchivePage> {
  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    context.read<ArchiveCubit>().load();
  }

  @override
  void initState() {
    super.initState();
    context.read<ArchiveCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.baseWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Archive', style: AppTextStyles.h1),
        centerTitle: screenWidth <= 600,
      ),
      body: BlocBuilder<ArchiveCubit, ArchiveState>(
        builder: (context, state) {
          if (state is ArchiveInitial || state is ArchiveLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.darkBlue),
            );
          }

          if (state is ArchiveLoaded && state.wines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.lightBlue.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No archived wines yet.\nWines removed from your cellar will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (state is ArchiveLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
              itemCount: state.wines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ArchiveCard(entry: state.wines[index]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final ArchivedWine entry;

  const _ArchiveCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final wine = entry.wine;
    final subtitle = [wine.winery, wine.region, wine.vintage?.toString()]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    final meta = [wine.type, wine.country]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    final dateStr = DateFormat('MMM d, y').format(entry.archivedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.router.push(WineDetailRoute(wine: wine, readOnly: true)),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Container(
                width: 80,
                height: 110,
                color: AppColors.lightBlue.withValues(alpha: 0.15),
                child: Center(child: AbstractWineBottle(type: wine.type, size: 50)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => context.router.push(WineDetailRoute(wine: wine, readOnly: true)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wine.name,
                      style: AppTextStyles.h2.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(meta, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Archived $dateStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.restore,
                  label: 'Restore',
                  color: AppColors.darkBlue,
                  onTap: () => _confirmRestore(context),
                ),
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.redAccent,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore wine?'),
        content: Text('${entry.wine.name} will be added back to your cellar with quantity 1.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ArchiveCubit>().restore(entry.wine.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete permanently?'),
        content: Text('${entry.wine.name} will be removed from your archive and cannot be recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ArchiveCubit>().permanentlyDelete(entry.wine.id);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
