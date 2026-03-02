import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_result_model.dart';

/// Returns nearby grocery stores.
///
/// Stubbed for Session 2 — returns an empty list.
/// Session 6 replaces this with a real Google Places API call.
final storesProvider = FutureProvider<List<StoreResult>>((_) async => []);
