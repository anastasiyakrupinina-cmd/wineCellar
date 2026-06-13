import 'package:wine_cellar/feature/wine/data/models/wine_bottle.dart';

class WineModel {
  final String id;
  final String name;

  final int? vintage;

  final String? type;
  final String? winery;
  final String? region;
  final String? country;

  final double? averageRating;
  final int? ratingsCount;

  final String? description;
  final String? alcoholContent;

  final List<WinePrice>? prices;
  final List<String>? foodPairings;
  final List<String>? grapes;
  final List<WineScore>? scores;

  final int quantity;
  final String? cellarLocation;
  final String? notice;

  final List<WineBottle>? bottles;

  WineModel({
    required this.id,
    required this.name,
    this.vintage,
    this.type,
    this.winery,
    this.region,
    this.country,
    this.averageRating,
    this.ratingsCount,
    this.description,
    this.alcoholContent,
    this.prices,
    this.foodPairings,
    this.grapes,
    this.scores,
    this.quantity = 1,
    this.cellarLocation,
    this.notice,
    this.bottles,
  });

  factory WineModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['wine'] is Map<String, dynamic>
            ? json['wine'] as Map<String, dynamic>
            : json;

    String? parseStringOrMap(dynamic value) {
      if (value == null) return null;

      if (value is Map) {
        return value['name']?.toString();
      }

      return value.toString();
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    List<WinePrice>? parsePrices(dynamic value) {
      if (value == null || value is! List) return null;

      return value
          .map(
            (e) => WinePrice.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    List<String>? parsePairings(dynamic value) {
      if (value == null || value is! List) return null;

      return value
          .map((e) {
            if (e is Map) {
              return e['food']?.toString() ?? '';
            }

            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String>? parseGrapes(dynamic value) {
      if (value == null || value is! List) return null;
      return value
          .map((e) => e is Map ? e['name']?.toString() ?? '' : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<WineScore>? parseScores(dynamic value) {
      if (value == null || value is! List) return null;
      return value
          .map((e) => WineScore.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return WineModel(
      id: data['id']?.toString().isNotEmpty == true
          ? data['id'].toString()
          : DateTime.now().millisecondsSinceEpoch.toString(),

      name: data['name']?.toString() ?? 'Unknown Wine',

      vintage: parseInt(data['vintage']),

      type: data['type']?.toString(),

      winery: parseStringOrMap(data['winery']),

      region: parseStringOrMap(data['region']),

      country:
          data['country']?.toString() ??
          (data['region'] is Map
              ? data['region']['country']?.toString()
              : null),

      averageRating: parseDouble(data['averageRating']),

      ratingsCount: parseInt(data['ratingsCount']),

      description: data['description']?.toString(),

      alcoholContent: data['alcoholContent']?.toString(),

      prices: parsePrices(data['prices']),

      foodPairings: parsePairings(data['pairings']),

      grapes: parseGrapes(data['grapes']),

      scores: parseScores(data['scores']),

      quantity: parseInt(data['quantity']) ?? 1,

      cellarLocation: data['cellarLocation']?.toString(),

      notice: data['notice']?.toString(),

      bottles: null, // loaded separately from wine_bottles table
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vintage': vintage,
      'type': type,
      'winery': winery,
      'region': region,
      'country': country,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'description': description,
      'alcoholContent': alcoholContent,
      'prices': prices?.map((p) => p.toJson()).toList(),
      'pairings': foodPairings?.map((f) => {'food': f}).toList(),
      'grapes': grapes?.map((g) => {'name': g}).toList(),
      'scores': scores?.map((s) => s.toJson()).toList(),
      'quantity': quantity,
      'cellarLocation': cellarLocation,
      'notice': notice,
    };
  }

  WineModel copyWith({
    String? id,
    String? name,
    int? vintage,
    String? type,
    String? winery,
    String? region,
    String? country,
    double? averageRating,
    int? ratingsCount,
    String? description,
    String? alcoholContent,
    List<WinePrice>? prices,
    List<String>? foodPairings,
    List<String>? grapes,
    List<WineScore>? scores,
    int? quantity,
    String? cellarLocation,
    String? notice,
    List<WineBottle>? bottles,
  }) {
    return WineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      vintage: vintage ?? this.vintage,
      type: type ?? this.type,
      winery: winery ?? this.winery,
      region: region ?? this.region,
      country: country ?? this.country,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      description: description ?? this.description,
      alcoholContent: alcoholContent ?? this.alcoholContent,
      prices: prices ?? this.prices,
      foodPairings: foodPairings ?? this.foodPairings,
      grapes: grapes ?? this.grapes,
      scores: scores ?? this.scores,
      quantity: quantity ?? this.quantity,
      cellarLocation: cellarLocation ?? this.cellarLocation,
      notice: notice ?? this.notice,
      bottles: bottles ?? this.bottles,
    );
  }
}

class WinePrice {
  final String? merchant;
  final double price;
  final String currency;
  final String? url;

  WinePrice({
    this.merchant,
    required this.price,
    required this.currency,
    this.url,
  });

  factory WinePrice.fromJson(Map<String, dynamic> json) {
    return WinePrice(
      merchant: json['merchantName']?.toString(),
      price: double.tryParse(json['price'].toString()) ?? 0,

      currency: json['currency']?.toString() ?? 'USD',

      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchantName': merchant,
      'price': price,
      'currency': currency,
      'url': url,
    };
  }
}

class WineScore {
  final double? score;
  final String? scoreText;
  final String reviewer;
  final String? reviewDate;

  WineScore({
    this.score,
    this.scoreText,
    required this.reviewer,
    this.reviewDate,
  });

  factory WineScore.fromJson(Map<String, dynamic> json) {
    return WineScore(
      score: json['score'] != null ? double.tryParse(json['score'].toString()) : null,
      scoreText: json['scoreText']?.toString(),
      reviewer: json['reviewer']?.toString() ?? '',
      reviewDate: json['reviewDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'scoreText': scoreText,
      'reviewer': reviewer,
      'reviewDate': reviewDate,
    };
  }
}
