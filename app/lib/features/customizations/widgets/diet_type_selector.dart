import 'package:flutter/material.dart';

const _dietOptions = [
  (value: 'omnivore', label: 'Omnivore', icon: '🍖'),
  (value: 'vegetarian', label: 'Vegetarian', icon: '🥗'),
  (value: 'vegan', label: 'Vegan', icon: '🌱'),
  (value: 'pescatarian', label: 'Pescatarian', icon: '🐟'),
];

/// Row of selectable diet-type chips.
class DietTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const DietTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dietOptions.map((opt) {
        final isSelected = opt.value == selected;
        return ChoiceChip(
          label: Text('${opt.icon} ${opt.label}'),
          selected: isSelected,
          onSelected: (_) => onChanged(opt.value),
        );
      }).toList(),
    );
  }
}
