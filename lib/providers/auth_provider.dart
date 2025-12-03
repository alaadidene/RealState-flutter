import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import '../services/appwrite_service.dart';

// Auth State
class AuthState {
  final models.User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    models.User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AppwriteService _appwriteService;

  AuthNotifier(this._appwriteService) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _appwriteService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      // Don't show error for guest users (401 unauthorized)
      if (!e.toString().contains('401') && !e.toString().contains('unauthorized')) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _appwriteService.createEmailSession(
        email: email,
        password: password,
      );
      final user = await _appwriteService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _appwriteService.createAccount(
        email: email,
        password: password,
        name: name,
      );
      await signIn(email: email, password: password);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _appwriteService.loginWithGoogle();
      if (ok) {
        final user = await _appwriteService.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Google sign-in failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _appwriteService.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider instance
final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  final service = AppwriteService();
  service.init();
  return service;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthNotifier(appwriteService);
});

// Current User Provider
final currentUserProvider = Provider<models.User?>((ref) {
  return ref.watch(authProvider).user;
});
