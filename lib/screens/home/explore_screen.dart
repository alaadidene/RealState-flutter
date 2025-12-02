import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/properties_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Properties'),
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

          const SizedBox(height: 16),

          // Properties List
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
}
