class PurchaseRecord {
  final String id;
  final String wineId;
  final String? bottleSize;
  final int quantity;
  final double price;
  final String currency;
  final DateTime purchasedAt;
  final String? shopName;

  const PurchaseRecord({
    required this.id,
    required this.wineId,
    this.bottleSize,
    required this.quantity,
    required this.price,
    required this.currency,
    required this.purchasedAt,
    this.shopName,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) => PurchaseRecord(
    id: map['id'] as String,
    wineId: map['wine_id'] as String,
    bottleSize: map['bottle_size'] as String?,
    quantity: map['quantity'] as int,
    price: (map['price'] as num).toDouble(),
    currency: map['currency'] as String,
    purchasedAt: DateTime.fromMillisecondsSinceEpoch(map['purchased_at'] as int),
    shopName: map['shop_name'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'wine_id': wineId,
    'bottle_size': bottleSize,
    'quantity': quantity,
    'price': price,
    'currency': currency,
    'purchased_at': purchasedAt.millisecondsSinceEpoch,
    'shop_name': shopName,
  };

  PurchaseRecord copyWith({
    String? id,
    String? wineId,
    String? bottleSize,
    int? quantity,
    double? price,
    String? currency,
    DateTime? purchasedAt,
    String? shopName,
  }) => PurchaseRecord(
    id: id ?? this.id,
    wineId: wineId ?? this.wineId,
    bottleSize: bottleSize ?? this.bottleSize,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    shopName: shopName ?? this.shopName,
  );
}
