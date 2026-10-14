import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<CheckAuthSessionEvent>(_onCheckAuthSession);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthSession(
    CheckAuthSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await getCurrentUserUseCase(NoParams())
          .timeout(const Duration(seconds: 2));
      result.fold(
        (failure) => emit(Unauthenticated()),
        (user) {
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Masuk ke akun Anda...'));
    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mendaftarkan akun baru...'));
    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(Unauthenticated());
  }
}
