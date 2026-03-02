import 'package:flutter/material.dart';

const _allergyOptions = [
  'gluten',
  'dairy',
  'nuts',
  'peanuts',
  'shellfish',
  'fish',
  'eggs',
  'soy',
  'sesame',
];

/// Multi-select chip grid for common food allergies.
class AllergySelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const AllergySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(String allergy) {
    final updated = List<String>.from(selected);
    if (updated.contains(allergy)) {
      updated.remove(allergy);
    } else {
      updated.add(allergy);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allergyOptions.map((allergy) {
        final isSelected = selected.contains(allergy);
        return FilterChip(
          label: Text(_capitalize(allergy)),
          selected: isSelected,
          onSelected: (_) => _toggle(allergy),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
