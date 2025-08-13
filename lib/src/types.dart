import 'dart:async';

class RefreshTokens {
  final String accessToken;
  final String? refreshToken;
  const RefreshTokens({required this.accessToken, this.refreshToken});
}

typedef TokenProvider = FutureOr<String?> Function();
typedef TokenRefresher = Future<RefreshTokens> Function();
