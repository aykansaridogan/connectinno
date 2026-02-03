import 'package:bloc/bloc.dart';

import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userEmail;
  final bool isLoading;

  AuthState({required this.isAuthenticated, this.userEmail, this.isLoading = false});

  AuthState copyWith({bool? isAuthenticated, String? userEmail, bool? isLoading}) => AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        userEmail: userEmail ?? this.userEmail,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service;

  AuthCubit(this._service) : super(AuthState(isAuthenticated: _service.isAuthenticated, userEmail: _service.userEmail, isLoading: _service.isLoading));

  Future<void> login(String email, String password) async {
    emit(state.copyWith(isLoading: true));
    final ok = await _service.login(email, password);
    emit(AuthState(isAuthenticated: ok, userEmail: ok ? email : null, isLoading: false));
  }

  Future<void> signup(String email, String password) async {
    emit(state.copyWith(isLoading: true));
    final ok = await _service.signup(email, password);
    emit(AuthState(isAuthenticated: ok, userEmail: ok ? email : null, isLoading: false));
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoading: true));
    await _service.logout();
    emit(AuthState(isAuthenticated: false, userEmail: null, isLoading: false));
  }
}
