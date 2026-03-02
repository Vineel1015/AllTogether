import 'package:flutter/material.dart';

import '../models/store_result_model.dart';

/// Displays a single nearby store result.
///
/// Stubbed for Session 2 — populated with real data in Session 6
/// when Google Places integration is implemented.
class StoreCardWidget extends StatelessWidget {
  final StoreResult store;

  const StoreCardWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.store_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      store.name,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                store.address,
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (store.distance != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${store.distance!.toStringAsFixed(1)} km away',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
