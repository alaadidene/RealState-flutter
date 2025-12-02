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

  PropertiesState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter,
    this.searchQuery,
  });

  PropertiesState copyWith({
    List<PropertyDocument>? properties,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    String? searchQuery,
  }) {
    return PropertiesState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
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
      final properties = await _appwriteService.getProperties(
        filter: state.selectedFilter,
        query: state.searchQuery,
        limit: 20,
      );
      state = state.copyWith(properties: properties, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String? filter) {
    state = state.copyWith(selectedFilter: filter);
    loadProperties();
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
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
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getAgents();
});

// Agent by ID Provider
final agentByIdProvider =
    FutureProvider.family<AgentDocument?, String>((ref, agentId) async {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return await appwriteService.getAgentById(agentId);
});
