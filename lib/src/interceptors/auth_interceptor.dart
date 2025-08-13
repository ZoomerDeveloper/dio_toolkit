import 'package:dio/dio.dart';
import '../types.dart';

class AuthInterceptor extends Interceptor {
  final TokenProvider _tokenProvider;
  AuthInterceptor(this._tokenProvider);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
