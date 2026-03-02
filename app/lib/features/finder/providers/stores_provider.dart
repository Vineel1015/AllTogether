import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/app_result.dart';
import '../../../services/places_service.dart';
import '../models/store_result_model.dart';

final placesServiceProvider = Provider<PlacesService>((_) => PlacesService());

/// Returns nearby grocery stores using the device's current location.
///
/// Silently returns `[]` on permission denial or API failure — the stores
/// strip in [FinderScreen] is already hidden when the list is empty.
final storesProvider = FutureProvider<List<StoreResult>>((ref) async {
  // 1. Permission check / request
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return [];
  }

  // 2. Get current position (low accuracy is sufficient for a 5 km radius search)
  final pos = await Geolocator.getCurrentPosition(
    locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.low),
  );

  // 3. Fetch nearby grocery stores
  final result = await ref.read(placesServiceProvider).getNearbyStores(
        lat: pos.latitude,
        lng: pos.longitude,
      );

  return result is AppSuccess<List<StoreResult>> ? result.data : [];
});
