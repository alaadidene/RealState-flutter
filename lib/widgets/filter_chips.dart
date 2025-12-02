import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class FilterChips extends StatelessWidget {
  final String? selectedFilter;
  final void Function(String?) onFilterSelected;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'All', 'value': null},
      {'label': 'For Rent', 'value': 'rent'},
      {'label': 'For Sale', 'value': 'sale'},
      {'label': 'Apartment', 'value': 'apartment'},
      {'label': 'House', 'value': 'house'},
      {'label': 'Villa', 'value': 'villa'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['value'];

          return FilterChip(
            label: Text(filter['label'] as String),
            selected: isSelected,
            onSelected: (selected) {
              onFilterSelected(selected ? filter['value'] : null);
            },
            selectedColor: AppTheme.primary,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.grey500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }
}
