import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/properties_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/advanced_filters_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Properties'),
        actions: [
          // Advanced Filters Button
          IconButton(
            onPressed: () {
              AdvancedFiltersSheet.show(
                context: context,
                minPrice: propertiesState.minPrice,
                maxPrice: propertiesState.maxPrice,
                minBeds: propertiesState.minBeds,
                bathrooms: propertiesState.bathrooms,
                facilities: propertiesState.facilities,
                sort: propertiesState.sort,
                onApply: ({minPrice, maxPrice, minBeds, bathrooms, facilities, sort}) {
                  ref.read(propertiesProvider.notifier).setAdvancedFilters(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    minBeds: minBeds,
                    bathrooms: bathrooms,
                    facilities: facilities,
                    sort: sort,
                  );
                },
              );
            },
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters(propertiesState))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              onSearch: (query) {
                ref.read(propertiesProvider.notifier).setSearchQuery(query);
              },
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FilterChips(
              selectedFilter: propertiesState.selectedFilter,
              onFilterSelected: (filter) {
                ref.read(propertiesProvider.notifier).setFilter(filter);
              },
            ),
          ),

          // Property Count and View Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${propertiesState.properties.length} Properties',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Row(
                  children: [
                    // Full Map Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to full map view
                      },
                      icon: const Icon(Icons.location_on, size: 16, color: Colors.white),
                      label: const Text(
                        'Full Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Map/List Toggle Button
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showMap = !_showMap;
                        });
                      },
                      icon: Icon(
                        _showMap ? Icons.home : Icons.location_on,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        _showMap ? 'List' : 'Map',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0061FF),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Map View (when toggled)
          if (_showMap)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Map View',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Properties will appear on map',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Properties List
          if (!_showMap)
          Expanded(
            child: propertiesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : propertiesState.properties.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No properties found'),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: propertiesState.properties.length,
                        itemBuilder: (context, index) {
                          final property = propertiesState.properties[index];
                          return PropertyCard(property: property);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(PropertiesState state) {
    return state.minPrice != null ||
        state.maxPrice != null ||
        state.minBeds != null ||
        state.bathrooms != null ||
        (state.facilities != null && state.facilities!.isNotEmpty) ||
        (state.sort != null && state.sort != 'newest');
  }
}
