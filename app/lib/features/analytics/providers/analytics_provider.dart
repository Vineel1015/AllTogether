import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/providers/receipt_provider.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (_) => AnalyticsService(),
);

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, Analytics>(
  AnalyticsNotifier.new,
);

class AnalyticsNotifier extends AsyncNotifier<Analytics> {
  @override
  Future<Analytics> build() async {
    final receipts = await ref.watch(receiptsProvider.future);
    return ref.read(analyticsServiceProvider).compute(receipts);
  }
}
