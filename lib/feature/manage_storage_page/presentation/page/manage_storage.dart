import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/app_snackbar.dart';
import 'package:wine_cellar/core/widget/button.dart';
import 'package:wine_cellar/core/widget/text_field.dart';
import 'package:wine_cellar/feature/manage_storage_page/presentation/page/manage_storage_cubit.dart';
import 'package:wine_cellar/feature/manage_storage_page/presentation/page/manage_storage_state.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/storage_model.dart';

@RoutePage()
class ManageStoragePage extends StatelessWidget {
  const ManageStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ManageStorageCubit>()..loadCabinets(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.baseWhite,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.darkBlue),
              title: Text('My Storage', style: AppTextStyles.h1.copyWith(fontSize: 24)),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () => _showAddCabinetDialog(context),
                  icon: const Icon(Icons.add, color: AppColors.darkBlue),
                ),
              ],
            ),

            body: BlocConsumer<ManageStorageCubit, ManageStorageState>(
              listener: (context, state) {
                if (state is ManageStorageError) {
                  AppSnackBar.show(context, message: state.message, isError: true);
                }
              },
              builder: (context, state) {
                if (state is ManageStorageLoading || state is ManageStorageInitial) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.darkBlue));
                }

                if (state is ManageStorageLoaded) {
                  if (state.cabinets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shelves, size: 80, color: AppColors.lightBlue.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Your storage is empty.\nAdd your first wine cabinet or shelf!',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.darkBlue,
                    onRefresh: () => context.read<ManageStorageCubit>().loadCabinets(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(bottom: 100),
                      itemCount: state.cabinets.length,
                      itemBuilder: (context, index) {
                        return _buildCabinetCard(context, state.cabinets[index]);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCabinetCard(BuildContext context, CabinetModel cabinet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.darkBlue.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.darkBlue,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(cabinet.name, style: AppTextStyles.h2),
        subtitle: Text(
          '${cabinet.shelves.length} shelves',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          if (cabinet.shelves.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No shelves in this storage yet.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...cabinet.shelves.map((shelf) => _buildShelf(shelf)),

          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Add Shelf',
                    isSecondary: true,
                    icon: Icons.add,
                    onPressed: () => _showAddShelfDialog(context, cabinet),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _confirmDeleteCabinet(context, cabinet),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelf(ShelfModel shelf) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shelf.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: shelf.positions.map((pos) => _buildBottleSpot(pos)).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottleSpot(BottlePositionModel pos) {
    final isOccupied = pos.wineId != null && pos.wineId!.isNotEmpty;

    return Tooltip(
      message: isOccupied ? 'Occupied Spot' : 'Empty Spot',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isOccupied ? AppColors.darkBlue : AppColors.lightBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOccupied ? AppColors.darkBlue : AppColors.lightBlue.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: isOccupied
              ? const Icon(Icons.wine_bar, color: AppColors.baseWhite, size: 22)
              : Text('${pos.index}', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
      ),
    );
  }

  void _showAddCabinetDialog(BuildContext context) {
    final controller = TextEditingController();
    final cubit = context.read<ManageStorageCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Storage Name', controller: controller, hint: 'e.g. Main Cellar, Fridge'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                cubit.addCabinet(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddShelfDialog(BuildContext context, CabinetModel cabinet) {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '10');
    final cubit = context.read<ManageStorageCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Shelf'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Shelf Name', controller: nameController, hint: 'e.g. Top Shelf, Section A'),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bottle Capacity',
              controller: countController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final count = int.tryParse(countController.text) ?? 10;
              if (nameController.text.isNotEmpty && count > 0) {
                cubit.addShelf(cabinet, nameController.text, count);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCabinet(BuildContext context, CabinetModel cabinet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete storage?'),
        content: Text(
          'Are you sure you want to delete "${cabinet.name}"?\nAll wines from this storage will be moved to Unassigned.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ManageStorageCubit>().deleteCabinet(cabinet);
    }
  }
}
