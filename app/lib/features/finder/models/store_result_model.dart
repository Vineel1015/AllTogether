/// A nearby grocery store result from the Google Places API.
///
/// This model is defined in Session 2 but populated in Session 6
/// when the Google Places integration is implemented.
class StoreResult {
  final String placeId;
  final String name;
  final String address;

  /// Distance from the user's location in kilometres. Null when unavailable.
  final double? distance;

  const StoreResult({
    required this.placeId,
    required this.name,
    required this.address,
    this.distance,
  });

  factory StoreResult.fromJson(Map<String, dynamic> json) => StoreResult(
        placeId: json['place_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        distance: (json['distance'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'name': name,
        'address': address,
        if (distance != null) 'distance': distance,
      };
}
