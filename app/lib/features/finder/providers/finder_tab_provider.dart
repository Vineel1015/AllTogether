import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected tab in the [FinderScreen] (0 = Plan, 1 = Shopping).
final finderTabProvider = StateProvider<int>((ref) => 0);
