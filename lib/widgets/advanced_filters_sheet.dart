import 'package:flutter/material.dart';

class AdvancedFiltersSheet extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialMinBeds;
  final int? initialBathrooms;
  final List<String>? initialFacilities;
  final String? initialSort;
  final void Function({
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    int? bathrooms,
    List<String>? facilities,
    String? sort,
  }) onApply;

  const AdvancedFiltersSheet({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinBeds,
    this.initialBathrooms,
    this.initialFacilities,
    this.initialSort,
    required this.onApply,
  });

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();

  static Future<void> show({
    required BuildContext context,
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    int? bathrooms,
    List<String>? facilities,
    String? sort,
    required void Function({
      double? minPrice,
      double? maxPrice,
      int? minBeds,
      int? bathrooms,
      List<String>? facilities,
      String? sort,
    }) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFiltersSheet(
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialMinBeds: minBeds,
        initialBathrooms: bathrooms,
        initialFacilities: facilities,
        initialSort: sort,
        onApply: onApply,
      ),
    );
  }
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  int? _selectedMinBeds;
  int? _selectedBathrooms;
  late List<String> _selectedFacilities;
  String _selectedSort = 'newest';

  final List<String> _facilityOptions = [
    'Swimming Pool',
    'Gym',
    'Parking',
    'Garden',
    'Balcony',
    'Security',
    'Air Conditioning',
    'Heating',
    'Elevator',
    'Furnished',
  ];

  final Map<String, String> _sortOptions = {
    'newest': 'Newest First',
    'price_high': 'Price: High to Low',
    'price_low': 'Price: Low to High',
    'rating': 'Highest Rated',
  };

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.initialMinPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '',
    );
    _selectedMinBeds = widget.initialMinBeds;
    _selectedBathrooms = widget.initialBathrooms;
    _selectedFacilities = List.from(widget.initialFacilities ?? []);
    _selectedSort = widget.initialSort ?? 'newest';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedMinBeds = null;
      _selectedBathrooms = null;
      _selectedFacilities.clear();
      _selectedSort = 'newest';
    });
  }

  void _applyFilters() {
    widget.onApply(
      minPrice: _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null,
      maxPrice: _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null,
      minBeds: _selectedMinBeds,
      bathrooms: _selectedBathrooms,
      facilities: _selectedFacilities.isNotEmpty ? _selectedFacilities : null,
      sort: _selectedSort,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Price',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bedrooms
                  const Text(
                    'Minimum Bedrooms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: List.generate(5, (index) {
                      final beds = index + 1;
                      return ChoiceChip(
                        label: Text('$beds${beds == 5 ? '+' : ''}'),
                        selected: _selectedMinBeds == beds,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMinBeds = selected ? beds : null;
                          });
                        },
                        selectedColor: const Color(0xFF0061FF),
                        labelStyle: TextStyle(
                          color: _selectedMinBeds == beds
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Bathrooms
                  const Text(
                    'Bathrooms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: List.generate(4, (index) {
                      final baths = index + 1;
                      return ChoiceChip(
                        label: Text('$baths${baths == 4 ? '+' : ''}'),
                        selected: _selectedBathrooms == baths,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBathrooms = selected ? baths : null;
                          });
                        },
                        selectedColor: const Color(0xFF0061FF),
                        labelStyle: TextStyle(
                          color: _selectedBathrooms == baths
                              ? Colors.white
                              : Colors.black,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Facilities
                  const Text(
                    'Facilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _facilityOptions.map((facility) {
                      final isSelected = _selectedFacilities.contains(facility);
                      return FilterChip(
                        label: Text(facility),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFacilities.add(facility);
                            } else {
                              _selectedFacilities.remove(facility);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF0061FF).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF0061FF),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0061FF)
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Sort By
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _sortOptions.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSort = value);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Footer Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF0061FF)),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0061FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0061FF),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
