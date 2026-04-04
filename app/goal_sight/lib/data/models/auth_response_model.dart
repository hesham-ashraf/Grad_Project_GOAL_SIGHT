import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: (json['token'] ?? '').toString(),
      user: UserModel.fromJson((json['user'] ?? {}) as Map<String, dynamic>),
    );
  }
}
