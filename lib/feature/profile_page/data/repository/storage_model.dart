class CabinetModel {
  final String id;
  final String name;
  final List<ShelfModel> shelves;

  CabinetModel({required this.id, required this.name, this.shelves = const []});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shelves': shelves.map((e) => e.toJson()).toList(),
  };

  factory CabinetModel.fromJson(Map<String, dynamic> json) => CabinetModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    shelves:
        (json['shelves'] as List<dynamic>?)
            ?.map((e) => ShelfModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
  );
}

class ShelfModel {
  final String id;
  final String name;
  final List<BottlePositionModel> positions;

  ShelfModel({required this.id, required this.name, this.positions = const []});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'positions': positions.map((e) => e.toJson()).toList(),
  };

  factory ShelfModel.fromJson(Map<String, dynamic> json) => ShelfModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    positions:
        (json['positions'] as List<dynamic>?)
            ?.map((e) => BottlePositionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
  );
}

class BottlePositionModel {
  final String id;
  final int index;
  final String? wineId;

  BottlePositionModel({required this.id, required this.index, this.wineId});

  Map<String, dynamic> toJson() => {'id': id, 'index': index, 'wineId': wineId};

  factory BottlePositionModel.fromJson(Map<String, dynamic> json) => BottlePositionModel(
    id: json['id'] as String,
    index: json['index'] as int? ?? 0,
    wineId: json['wineId'] as String?,
  );
}
