import 'dart:async';
import 'package:dio/dio.dart';
import '../types.dart';

class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final TokenProvider tokenProvider;
  final TokenRefresher refresher;
  final void Function(RefreshTokens tokens)? onTokensUpdated;
  final bool Function(RequestOptions req)? isRefreshRequest;

  Future<RefreshTokens>?
      _refreshing; // общая Future, чтобы очередь ждала один рефреш

  RefreshInterceptor({
    required this.dio,
    required this.tokenProvider,
    required this.refresher,
    this.onTokensUpdated,
    this.isRefreshRequest,
  });

  bool _isAuthError(DioException err) => err.response?.statusCode == 401;

  bool _shouldBypass(RequestOptions req) {
    if (req.extra['__retried__'] == true) return true; // уже ретраили
    if (isRefreshRequest != null && isRefreshRequest!(req))
      return true; // сам рефреш
    return false;
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isAuthError(err) || _shouldBypass(err.requestOptions)) {
      return handler.next(err);
    }

    try {
      _refreshing ??= refresher();
      final tokens = await _refreshing!; // ждём общий рефреш
      onTokensUpdated?.call(tokens);
    } catch (_) {
      _refreshing = null;
      return handler.next(err); // рефреш не удался
    }
    _refreshing = null;

    // Пробуем повторить запрос с новым токеном
    try {
      final newToken = await tokenProvider();
      final req = err.requestOptions;
      if (newToken != null && newToken.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $newToken';
      } else {
        req.headers.remove('Authorization');
      }
      req.extra['__retried__'] = true;
      final response = await dio.fetch(req);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }
}
