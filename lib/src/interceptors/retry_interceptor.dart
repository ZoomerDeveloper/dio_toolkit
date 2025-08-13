import 'dart:async';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialBackoff;

  RetryInterceptor(
      {required this.dio,
      this.maxRetries = 2,
      this.initialBackoff = const Duration(milliseconds: 300)});

  bool _shouldRetry(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return true;
    }
    final status = e.response?.statusCode ?? 0;
    return status == 502 || status == 503 || status == 504;
  }

  Future<void> _sleep(int attempt) async {
    final delay = initialBackoff * (1 << (attempt - 1));
    await Future.delayed(delay);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final attempts = (req.extra['retry_attempt'] as int?) ?? 0;

    if (attempts < maxRetries && _shouldRetry(err)) {
      await _sleep(attempts + 1);
      try {
        req.extra['retry_attempt'] = attempts + 1;
        final response = await dio.fetch(req);
        return handler.resolve(response);
      } catch (_) {
        // fallthrough
      }
    }
    return handler.next(err);
  }
}
