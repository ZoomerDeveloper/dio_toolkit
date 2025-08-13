import 'package:dio/dio.dart';
import '../../cache.dart';

class CacheInterceptor extends Interceptor {
  final CacheStore store;
  CacheInterceptor(this.store);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final opts = CacheOptions.fromExtra(options.extra);
    if (opts != null &&
        options.method.toUpperCase() == 'GET' &&
        !opts.forceRefresh) {
      final key = store.keyFor(options);
      final entry = store.get(key);
      if (entry != null && !entry.isExpired) {
        final cached = Response(
          requestOptions: options,
          data: entry.data,
          statusCode: entry.statusCode,
          headers: entry.headers,
        );
        return handler.resolve(cached);
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final opts = CacheOptions.fromExtra(response.requestOptions.extra);
    final options = response.requestOptions;
    if (opts != null && options.method.toUpperCase() == 'GET') {
      final key = store.keyFor(options);
      store.set(
        key,
        CacheEntry(
          data: response.data,
          statusCode: response.statusCode ?? 200,
          headers: response.headers,
          insertedAt: DateTime.now(),
          maxAge: opts.maxAge,
        ),
      );
    }
    super.onResponse(response, handler);
  }
}
