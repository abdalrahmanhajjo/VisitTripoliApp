import 'api_service.dart';

num? _parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

class Coupon {
  final String id;
  final String code;
  final String discountType;
  final num discountValue;
  final num? minPurchase;
  final String? validUntil;
  final int? usageLimit;
  final String? placeId;
  final String? placeName;
  final String? tourId;
  final String? tourName;
  final String? eventId;
  final String? eventName;
  final bool usedByMe;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minPurchase,
    this.validUntil,
    this.usageLimit,
    this.placeId,
    this.placeName,
    this.tourId,
    this.tourName,
    this.eventId,
    this.eventName,
    this.usedByMe = false,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: json['id']?.toString() ?? '',
        code: json['code'] as String? ?? '',
        discountType: json['discount_type'] as String? ?? 'percent',
        discountValue: _parseNum(json['discount_value']) ?? 0,
        minPurchase: _parseNum(json['min_purchase'])?.toDouble(),
        validUntil: json['valid_until'] as String?,
        usageLimit: _parseNum(json['usage_limit'])?.toInt(),
        placeId: json['place_id']?.toString(),
        placeName: json['place_name'] as String?,
        tourId: json['tour_id']?.toString(),
        tourName: json['tour_name'] as String?,
        eventId: json['event_id']?.toString(),
        eventName: json['event_name'] as String?,
        usedByMe: json['used_by_me'] == true,
      );

  String get displayValue =>
      discountType == 'percent' ? '${discountValue.toInt()}% off' : '\$$discountValue off';
}

class PlaceOffer {
  final String id;
  final String placeId;
  final String title;
  final String? description;
  final String discountType;
  final num? discountValue;
  final String? expiresAt;
  final String? placeName;
  final List<String> placeImages;

  PlaceOffer({
    required this.id,
    required this.placeId,
    required this.title,
    this.description,
    required this.discountType,
    this.discountValue,
    this.expiresAt,
    this.placeName,
    this.placeImages = const [],
  });

  factory PlaceOffer.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];
    final raw = json['place_images'];
    if (raw is List) {
      imgs = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return PlaceOffer(
      id: json['id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      discountType: json['discount_type'] as String? ?? 'percent',
      discountValue: _parseNum(json['discount_value'])?.toDouble(),
      expiresAt: json['expires_at'] as String?,
      placeName: json['place_name'] as String?,
      placeImages: imgs,
    );
  }

  String get displayValue => discountType == 'percent' && discountValue != null
      ? '${discountValue!.toInt()}% off'
      : discountType == 'fixed' && discountValue != null
          ? '\$$discountValue off'
          : title;
}

class OfferProposal {
  final String id;
  final String placeId;
  final String? placeName;
  final String message;
  final String? phone;
  final String status;
  final String? createdAt;
  final String? restaurantResponse;
  final String? restaurantRespondedAt;

  OfferProposal({
    required this.id,
    required this.placeId,
    this.placeName,
    required this.message,
    this.phone,
    required this.status,
    this.createdAt,
    this.restaurantResponse,
    this.restaurantRespondedAt,
  });

  factory OfferProposal.fromJson(Map<String, dynamic> json) => OfferProposal(
        id: json['id']?.toString() ?? '',
        placeId: json['placeId'] ?? json['place_id']?.toString() ?? '',
        placeName: json['placeName'] ?? json['place_name'] as String?,
        message: json['message'] as String? ?? '',
        phone: json['phone'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] ?? json['created_at']?.toString(),
        restaurantResponse: json['restaurantResponse'] ?? json['restaurant_response'] as String?,
        restaurantRespondedAt: json['restaurantRespondedAt'] ?? json['restaurant_responded_at']?.toString(),
      );

  bool get hasResponse => restaurantResponse != null && restaurantResponse!.isNotEmpty;
}

class DealsService {
  DealsService._();
  static final DealsService instance = DealsService._();

  Future<List<Coupon>> getCoupons({String? authToken}) async {
    final res = await ApiService.instance.getCoupons(authToken: authToken);
    final list = (res['coupons'] as List?) ?? [];
    return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> validateCoupon(String code, {String? authToken}) async {
    return ApiService.instance.validateCoupon(code, authToken: authToken);
  }

  Future<Map<String, dynamic>> redeemCoupon(String code, String authToken) async {
    return ApiService.instance.redeemCoupon(code, authToken);
  }

  Future<void> proposeOfferToRestaurant(String authToken, String placeId, String message, String phone, {String? discountType, num? discountValue}) async {
    await ApiService.instance.proposeOfferToRestaurant(authToken, placeId, message, phone, discountType: discountType, discountValue: discountValue);
  }

  Future<List<PlaceOffer>> getOffers() async {
    final res = await ApiService.instance.getOffers();
    final list = (res['offers'] as List?) ?? [];
    return list.map((e) => PlaceOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, String>>> getPlacesForPropose() async {
    final list = await ApiService.instance.getPlaces(categoryId: 'food');
    return list.map((e) {
      final m = e is Map ? e as Map<String, dynamic> : <String, dynamic>{};
      return {'id': m['id']?.toString() ?? '', 'name': m['name'] as String? ?? ''};
    }).where((p) => p['id']!.isNotEmpty && p['name']!.isNotEmpty).toList();
  }

  Future<List<OfferProposal>> getMyProposals(String authToken) async {
    final res = await ApiService.instance.getMyProposals(authToken);
    final list = (res['proposals'] as List?) ?? [];
    return list.map((e) => OfferProposal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PlaceOffer>> getOffersForPlace(String placeId) async {
    final res = await ApiService.instance.getOffersForPlace(placeId);
    final list = (res['offers'] as List?) ?? [];
    return list.map((e) => PlaceOffer.fromJson(e as Map<String, dynamic>)).toList();
  }
}
