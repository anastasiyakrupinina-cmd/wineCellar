import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';
import 'package:wine_cellar/core/dependencies/get_it.dart';
import 'package:wine_cellar/core/style/app_text_style.dart';
import 'package:wine_cellar/core/widget/app_snackbar.dart';
import 'package:wine_cellar/feature/main_page/data/reposiotry/main_repository.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/profile_repository.dart';
import 'package:wine_cellar/feature/profile_page/data/repository/storage_model.dart';
import 'package:wine_cellar/feature/wine/data/models/wine_model.dart';

class StorageLocationDialog extends StatefulWidget {
  final WineModel wine;
  final bool removeMode;
  final int? maxRemovable;
  final String? bottleSize;
  final bool lockInitialSpots;
  final int? maxNewSpots;

  const StorageLocationDialog({
    super.key,
    required this.wine,
    this.removeMode = false,
    this.maxRemovable,
    this.bottleSize,
    this.lockInitialSpots = false,
    this.maxNewSpots,
  });

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
                final sizeMatches = !widget.removeMode ||
                    widget.bottleSize == null ||
                    pos.bottleSize == widget.bottleSize;
                if (sizeMatches) {
                  _selectedCabinet ??= cab;
                  _selectedShelf ??= shelf;
                  _selectedSpotIds.add(pos.id);
                  _initialSelectedSpotIds.add(pos.id);
                }
              }
            }
          }
        }

        if (!widget.removeMode) {
          _restoreSelectedSpotsFromWineLocation();
        }
        _initialSelectedSpotIds.addAll(_selectedSpotIds);

        if (_selectedCabinet == null && (widget.wine.cellarLocation?.contains('Unassigned') ?? false)) {
          _selectedCabinet = _unassignedCabinet;
        }

        if (widget.lockInitialSpots && widget.bottleSize != null) {
          final hasSpotsForThisSize = _cabinets.any((cab) =>
              cab.shelves.any((shelf) =>
                  shelf.positions.any((pos) =>
                      pos.wineId == widget.wine.id && pos.bottleSize == widget.bottleSize)));
          if (!hasSpotsForThisSize) {
            _selectedCabinet = null;
            _selectedShelf = null;
          }
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
    if (widget.removeMode) {
      await _saveLocationRemoveMode();
      return;
    }

    await getIt<MainRepository>().saveWine(widget.wine);
    if (!mounted) return;

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
              return BottlePositionModel(
                id: pos.id, index: pos.index,
                wineId: widget.wine.id, bottleSize: widget.bottleSize,
              );
            }
          } else if (isCurrentlySelected) {
            shelfNeedsUpdate = true;
            return BottlePositionModel(id: pos.id, index: pos.index, wineId: null, bottleSize: null);
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

      Navigator.pop(context, {'location': newLocationString, 'quantity': totalQuantity});
    }
  }

  Future<void> _saveLocationRemoveMode() async {
    final removedSpots = _initialSelectedSpotIds.difference(_selectedSpotIds);
    final removedCount = removedSpots.length;

    if (removedCount == 0) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await _confirmLocationChange(removedCount: removedCount, addedCount: 0);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    final totalQuantity = widget.wine.quantity;
    final newQuantity = totalQuantity - removedCount;
    final repo = getIt<ProfileRepository>();
    final List<String> locationParts = [];

    for (var cab in _cabinets) {
      bool cabinetNeedsUpdate = false;
      final updatedShelves = cab.shelves.map((shelf) {
        bool shelfNeedsUpdate = false;
        final shelfSpotIndexes = <int>[];
        final updatedPositions = shelf.positions.map((pos) {
          final shouldBeSelected = _selectedSpotIds.contains(pos.id);
          final wasPreSelected = _initialSelectedSpotIds.contains(pos.id);
          if (shouldBeSelected) {
            shelfSpotIndexes.add(pos.index);
          } else if (wasPreSelected) {
            shelfNeedsUpdate = true;
            return BottlePositionModel(id: pos.id, index: pos.index, wineId: null, bottleSize: null);
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

    if (!mounted) return;
    if (_selectedSpotIds.length < newQuantity) locationParts.add('Unassigned');
    Navigator.pop(context, {
      'location': locationParts.join(' ; '),
      'quantity': newQuantity,
      'removedCount': removedCount,
    });
  }

  Future<bool> _confirmLocationChange({
    required int removedCount,
    required int addedCount,
  }) async {
    final int affectedCount = removedCount > 0 ? removedCount : addedCount;
    final bottleWord = affectedCount == 1 ? 'bottle' : 'bottles';

    final String message;
    if (widget.removeMode) {
      message = '$affectedCount $bottleWord will be permanently removed from your cellar.';
    } else {
      final bool removeOnly = removedCount > 0 && addedCount == 0;
      message = removeOnly
          ? 'The selected $bottleWord will be moved to Unassigned.'
          : 'The selected $bottleWord location will be updated.';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.removeMode ? 'Remove bottles?' : 'Confirm location change'),
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

    final effectiveMax = widget.maxRemovable ?? widget.wine.quantity;
    final removedSoFar = widget.removeMode
        ? _initialSelectedSpotIds.difference(_selectedSpotIds).length
        : 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.removeMode ? 'Remove from Storage' : 'Select Location'),
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
                if (!widget.removeMode)
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
            if (!widget.removeMode && _selectedCabinet?.id == _unassignedCabinetId)
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
              Text(
                widget.removeMode ? 'Tap a spot to remove a bottle' : 'Select spot(s)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedShelf!.positions.map((pos) {
                  final isSelected = _selectedSpotIds.contains(pos.id);
                  final bool isDisabled;
                  if (widget.removeMode) {
                    final isOwnedByThisWine = _initialSelectedSpotIds.contains(pos.id);
                    final atLimit = isSelected && removedSoFar >= effectiveMax;
                    isDisabled = !isOwnedByThisWine || atLimit;
                  } else {
                    final isOccupied = pos.wineId != null && pos.wineId != widget.wine.id;
                    final maxAllowed = widget.maxNewSpots != null
                        ? _initialSelectedSpotIds.length + widget.maxNewSpots!
                        : widget.wine.quantity;
                    final reachedLimit = !isSelected && _selectedSpotIds.length >= maxAllowed;
                    isDisabled = isOccupied || reachedLimit;
                  }

                  final isLocked = widget.lockInitialSpots && _initialSelectedSpotIds.contains(pos.id);
                  final isOtherSize = widget.lockInitialSpots &&
                      widget.bottleSize != null &&
                      pos.wineId == widget.wine.id &&
                      pos.bottleSize != widget.bottleSize;

                  final Color tileColor;
                  if (isDisabled) {
                    tileColor = Colors.grey.shade300;
                  } else if (isLocked) {
                    tileColor = AppColors.darkBlue;
                  } else if (widget.removeMode && !isSelected) {
                    tileColor = Colors.redAccent.withValues(alpha: 0.15);
                  } else if (isSelected) {
                    tileColor = AppColors.darkBlue;
                  } else {
                    tileColor = AppColors.lightBlue.withValues(alpha: 0.1);
                  }

                  return GestureDetector(
                    onTap: (isDisabled || isLocked)
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
                        color: tileColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (widget.removeMode && !isSelected && !isDisabled)
                                  ? Colors.redAccent
                                  : (isSelected && !isOtherSize ? AppColors.darkBlue : Colors.transparent),
                        ),
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
                widget.removeMode
                    ? 'Removing: $removedSoFar'
                    : widget.lockInitialSpots && widget.maxNewSpots != null
                        ? 'Selected: ${_selectedSpotIds.difference(_initialSelectedSpotIds).length}/${widget.maxNewSpots}'
                        : 'Selected: ${_selectedSpotIds.length}/${widget.wine.quantity}',
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
          child: Text(
            widget.removeMode ? 'Remove' : 'Save',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
