import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/properties_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/property_card.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesState = ref.watch(propertiesProvider);
    final user = ref.watch(currentUserProvider);
    
    // Filter properties by current user
    final myProperties = propertiesState.properties.where((p) => p.agentId == user?.$id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-property'),
          ),
        ],
      ),
      body: propertiesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : propertiesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${propertiesState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(propertiesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : myProperties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home_work, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No listings yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/create-property'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Listing'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(propertiesProvider),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: myProperties.length,
                        itemBuilder: (context, index) {
                          return PropertyCard(property: myProperties[index]);
                        },
                      ),
                    ),
      floatingActionButton: myProperties.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-property'),
              icon: const Icon(Icons.add),
              label: const Text('New Listing'),
            )
          : null,
    );
  }
}
