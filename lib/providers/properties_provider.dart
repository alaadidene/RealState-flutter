import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

// Export currentUserProvider for use in other files
export 'auth_provider.dart' show currentUserProvider;

// Properties State
class PropertiesState {
  final List<PropertyDocument> properties;
  final bool isLoading;
  final String? error;
  final String? selectedFilter;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final int? minBeds;
  final int? bathrooms;
  final List<String>? facilities;
  final String? sort;

  PropertiesState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.minBeds,
    this.bathrooms,
    this.facilities,
    this.sort,
  });

  PropertiesState copyWith({
    List<PropertyDocument>? properties,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    int? bathrooms,
    List<String>? facilities,
    String? sort,
  }) {
    return PropertiesState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBeds: minBeds ?? this.minBeds,
      bathrooms: bathrooms ?? this.bathrooms,
      facilities: facilities ?? this.facilities,
      sort: sort ?? this.sort,
    );
  }
}

// Properties Notifier
class PropertiesNotifier extends StateNotifier<PropertiesState> {
  final AppwriteService _appwriteService;

  PropertiesNotifier(this._appwriteService) : super(PropertiesState()) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var properties = await _appwriteService.getProperties(
        filter: state.selectedFilter,
        query: state.searchQuery,
        limit: 100,
      );

      // Apply client-side filtering
      properties = _applyFilters(properties);

      state = state.copyWith(properties: properties, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<PropertyDocument> _applyFilters(List<PropertyDocument> properties) {
    var filtered = properties;

    // Price range
    if (state.minPrice != null) {
      filtered = filtered.where((p) => p.price >= state.minPrice!).toList();
    }
    if (state.maxPrice != null) {
      filtered = filtered.where((p) => p.price <= state.maxPrice!).toList();
    }

    // Bedrooms
    if (state.minBeds != null) {
      filtered = filtered.where((p) => p.bedrooms >= state.minBeds!).toList();
    }

    // Bathrooms
    if (state.bathrooms != null) {
      filtered = filtered.where((p) => p.bathrooms >= state.bathrooms!).toList();
    }

    // Facilities
    if (state.facilities != null && state.facilities!.isNotEmpty) {
      filtered = filtered.where((p) {
        return state.facilities!.every((f) => p.facilities.contains(f));
      }).toList();
    }

    // Sort
    switch (state.sort) {
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  void setFilter(String? filter) {
    state = state.copyWith(selectedFilter: filter);
    loadProperties();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    loadProperties();
  }

  void setAdvancedFilters({
    double? minPrice,
    double? maxPrice,
    int? minBeds,
    int? bathrooms,
    List<String>? facilities,
    String? sort,
  }) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minBeds: minBeds,
      bathrooms: bathrooms,
      facilities: facilities,
      sort: sort,
    );
    loadProperties();
  }

  Future<void> refresh() async {
    await loadProperties();
  }
}

// Providers
final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertiesState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return PropertiesNotifier(appwriteService);
});

// Single Property Provider
final propertyByIdProvider =
    FutureProvider.family<PropertyDocument?, String>((ref, propertyId) async {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getPropertyById(propertyId);
});

// Property Reviews Provider
final propertyReviewsProvider =
    FutureProvider.family<List<ReviewDocument>, String>((ref, propertyId) async {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getPropertyReviews(propertyId);
});

// Agents Provider
final agentsProvider = FutureProvider<List<AgentDocument>>((ref) async {
  // TODO: Implement getAgents method
  return [];
});

// Latest Properties Provider (for featured carousel)
final latestPropertiesProvider = FutureProvider<List<PropertyDocument>>((ref) async {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getProperties(limit: 5);
});

// Agent by ID Provider
final agentByIdProvider =
    FutureProvider.family<AgentDocument?, String>((ref, agentId) async {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getAgentById(agentId);
});
