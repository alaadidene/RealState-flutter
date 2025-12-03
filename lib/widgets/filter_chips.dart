import 'package:flutter/material.dart';

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
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['value'];

          return GestureDetector(
            onTap: () {
              onFilterSelected(filter['value']);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0061FF)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF0061FF).withValues(alpha: 0.2),
                      ),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : const Color(0xFF1F2937),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
