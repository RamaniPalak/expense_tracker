import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String email;

  const Authenticated({required this.email});

  @override
  List<Object?> get props => [email];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Emitted after a successful OTP dispatch. Carries the OTP (for demo) and
/// the email so the verify screen knows which account to reset.
class PasswordResetOtpSent extends AuthState {
  final String email;

  /// The OTP returned by the server (demo only — in production this is sent
  /// via email and should NOT be returned to the client).
  final String otp;

  const PasswordResetOtpSent({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

/// Emitted after the password has been successfully reset.
class PasswordResetSuccess extends AuthState {}

