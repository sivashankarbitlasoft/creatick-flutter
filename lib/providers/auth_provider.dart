import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_service.dart';
import '../core/api_exception.dart';
import '../core/local_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { checking, loggedOut, loggedIn }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? false,
      error: error,
    );
  }

  static const initial = AuthState(status: AuthStatus.checking);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial) {
    _checkLoggedIn();
  }

  /// Runs once on app start - if a user was saved locally, log straight in
  /// without asking for credentials again.
  Future<void> _checkLoggedIn() async {
    final savedUser = await LocalStorage.loadUser();
    if (savedUser != null) {
      state = AuthState(status: AuthStatus.loggedIn, user: savedUser);
    } else {
      state = const AuthState(status: AuthStatus.loggedOut);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ApiService.login(email, password);
      await LocalStorage.saveUser(user);
      state = AuthState(status: AuthStatus.loggedIn, user: user);
    } on ApiException catch (e) {
      state = state.copyWith(
          status: AuthStatus.loggedOut, isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.loggedOut,
          isLoading: false,
          error: 'Could not reach the server. Check your connection.');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      await LocalStorage.saveUser(user);
      state = AuthState(status: AuthStatus.loggedIn, user: user);
    } on ApiException catch (e) {
      state = state.copyWith(
          status: AuthStatus.loggedOut, isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.loggedOut,
          isLoading: false,
          error: 'Could not reach the server. Check your connection.');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? password,
  }) async {
    final current = state.user;
    if (current == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await ApiService.updateProfile(
        userId: current.id,
        name: name,
        phone: phone,
        password: password,
      );
      await LocalStorage.saveUser(updated);
      state = AuthState(status: AuthStatus.loggedIn, user: updated);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (_) {
      state = state.copyWith(
          error: 'Could not reach the server. Check your connection.',
          isLoading: false);
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearUser();
    state = const AuthState(status: AuthStatus.loggedOut);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
