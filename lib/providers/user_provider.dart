import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

class UserProfileState {
  final String? name;
  final String? email;
  final String? avatar;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.name,
    this.email,
    this.avatar,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    String? name,
    String? email,
    String? avatar,
    bool? isLoading,
    String? error,
  }) => UserProfileState(
        name: name ?? this.name,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final AppwriteService _service;
  final Ref _ref;

  UserProfileNotifier(this._service, this._ref)
      : super(const UserProfileState()) {
    _load();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    state = UserProfileState(
      name: user.name,
      email: user.email,
      avatar: user.prefs.data['avatar'] as String?,
      isLoading: false,
    );
  }

  void refresh() => _load();

  Future<void> updateProfile({
    String? name,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (name != null) {
        await _service.account.updateName(name: name);
      }
      
      if (email != null) {
        await _service.account.updateEmail(email: email, password: '');
      }
      
      // Refresh auth to get updated user
      _ref.invalidate(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _load();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.account.updatePrefs(prefs: {'avatar': avatarUrl});
      state = state.copyWith(avatar: avatarUrl, isLoading: false);
      
      // Refresh auth
      _ref.invalidate(authProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final service = ref.watch(appwriteServiceProvider);
  return UserProfileNotifier(service, ref);
});
