class WineBottle {
  final String id;
  final String wineId;
  final String bottleSize;
  final int quantity;

  const WineBottle({
    required this.id,
    required this.wineId,
    required this.bottleSize,
    required this.quantity,
  });

  factory WineBottle.fromMap(Map<String, dynamic> map) => WineBottle(
    id: map['id'] as String,
    wineId: map['wine_id'] as String,
    bottleSize: map['bottle_size'] as String,
    quantity: map['quantity'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'wine_id': wineId,
    'bottle_size': bottleSize,
    'quantity': quantity,
  };

  WineBottle copyWith({String? id, String? wineId, String? bottleSize, int? quantity}) => WineBottle(
    id: id ?? this.id,
    wineId: wineId ?? this.wineId,
    bottleSize: bottleSize ?? this.bottleSize,
    quantity: quantity ?? this.quantity,
  );

  static const List<String> standardSizes = [
    '750ml',
    '375ml',
    '1.5L',
    '3L',
    '187ml',
  ];
}
