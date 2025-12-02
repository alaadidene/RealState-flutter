import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_models.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

// Favorites State
class FavoritesState {
  final List<FavoriteDocument> favorites;
  final Set<String> favoritePropertyIds;
  final bool isLoading;
  final String? error;

  FavoritesState({
    this.favorites = const [],
    this.favoritePropertyIds = const {},
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FavoriteDocument>? favorites,
    Set<String>? favoritePropertyIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      favoritePropertyIds: favoritePropertyIds ?? this.favoritePropertyIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool isFavorite(String propertyId) {
    return favoritePropertyIds.contains(propertyId);
  }
}

// Favorites Notifier
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final AppwriteService _appwriteService;
  final String? _userId;

  FavoritesNotifier(this._appwriteService, this._userId)
      : super(FavoritesState()) {
    if (_userId != null) {
      loadFavorites();
    }
  }

  Future<void> loadFavorites() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final favorites = await _appwriteService.getUserFavorites(_userId);
      final propertyIds = favorites.map((f) => f.propertyId).toSet();
      state = state.copyWith(
        favorites: favorites,
        favoritePropertyIds: propertyIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleFavorite(String propertyId) async {
    if (_userId == null) return false;

    try {
      if (state.isFavorite(propertyId)) {
        // Remove from favorites
        final favorite = state.favorites.firstWhere(
          (f) => f.propertyId == propertyId,
        );
        await _appwriteService.removeFromFavorites(favorite.id);
        
        final newFavorites = state.favorites.where((f) => f.id != favorite.id).toList();
        final newPropertyIds = Set<String>.from(state.favoritePropertyIds)
          ..remove(propertyId);
        
        state = state.copyWith(
          favorites: newFavorites,
          favoritePropertyIds: newPropertyIds,
        );
      } else {
        // Add to favorites
        final favorite = await _appwriteService.addToFavorites(
          userId: _userId,
          propertyId: propertyId,
        );
        
        if (favorite != null) {
          final newFavorites = [...state.favorites, favorite];
          final newPropertyIds = Set<String>.from(state.favoritePropertyIds)
            ..add(propertyId);
          
          state = state.copyWith(
            favorites: newFavorites,
            favoritePropertyIds: newPropertyIds,
          );
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  final user = ref.watch(currentUserProvider);
  return FavoritesNotifier(appwriteService, user?.$id);
});
