import 'dart:async';
import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'result.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import '../cache.dart';
import 'types.dart';

typedef Json = Map<String, dynamic>;
typedef Decoder<T> = T Function(Object? data);

/// Функция, которая возвращает текущий accessToken (или null)
/// Результат рефреша токена
/// Функция-рефрешер. Должна выполнить запрос рефреша и вернуть новые токены.
class DioToolkitClient {
  final Dio _dio;

  Dio get dio => _dio;

  DioToolkitClient._(this._dio);

  factory DioToolkitClient.withDefaults({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration sendTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    TokenProvider? tokenProvider,
    TokenRefresher? tokenRefresher,
    void Function(RefreshTokens tokens)? onTokensUpdated,
    bool Function(RequestOptions req)? isRefreshRequest,
    bool enableLogging = true,
    int maxRetries = 2,
    Duration initialBackoff = const Duration(milliseconds: 300),
    CacheStore? cacheStore,
    List<Interceptor> extraInterceptors = const [],
    void Function(RequestOptions options)? onBeforeRequest,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Auth header
    if (tokenProvider != null) {
      dio.interceptors.add(AuthInterceptor(tokenProvider));
    }

    // Refresh 401 -> queue & retry once
    if (tokenProvider != null && tokenRefresher != null) {
      dio.interceptors.add(
        RefreshInterceptor(
          dio: dio,
          tokenProvider: tokenProvider,
          refresher: tokenRefresher,
          onTokensUpdated: onTokensUpdated,
          isRefreshRequest: isRefreshRequest,
        ),
      );
    }

    // Retry transient
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        maxRetries: maxRetries,
        initialBackoff: initialBackoff,
      ),
    );

    // Optional in-memory cache
    if (cacheStore != null) {
      dio.interceptors.add(CacheInterceptor(cacheStore));
    }

    // Logging last (request/response)
    if (enableLogging) {
      dio.interceptors.add(LoggingInterceptor());
    }

    // Custom
    dio.interceptors.addAll(extraInterceptors);

    // Hook before request
    if (onBeforeRequest != null) {
      dio.interceptors.add(InterceptorsWrapper(onRequest: (opt, h) {
        onBeforeRequest(opt);
        h.next(opt);
      }));
    }

    return DioToolkitClient._(dio);
  }

  /// Унифицированный вызов с типобезопасным декодером.
  Future<Result<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Object? body,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Decoder<T>? decoder,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool followRedirects = true,
    int? validateStatusBelow = 400,
  }) async {
    try {
      final res = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: headers,
          followRedirects: followRedirects,
          extra: extra,
          validateStatus: (status) {
            if (status == null) return false;
            return status < (validateStatusBelow ?? 400);
          },
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      final data = decoder != null ? decoder(res.data) : res.data as T;
      return Success(data);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } catch (e) {
      return Failure(ApiException.unknown(message: e.toString()));
    }
  }

  // Shorthands
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Decoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        method: 'GET',
        query: query,
        headers: headers,
        extra: extra,
        decoder: decoder,
        cancelToken: cancelToken,
      );

  Future<Result<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Decoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        method: 'POST',
        body: body,
        query: query,
        headers: headers,
        extra: extra,
        decoder: decoder,
        cancelToken: cancelToken,
      );

  Future<Result<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Decoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        method: 'PUT',
        body: body,
        query: query,
        headers: headers,
        extra: extra,
        decoder: decoder,
        cancelToken: cancelToken,
      );

  Future<Result<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Decoder<T>? decoder,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        method: 'DELETE',
        body: body,
        query: query,
        headers: headers,
        extra: extra,
        decoder: decoder,
        cancelToken: cancelToken,
      );

  ApiException _mapDioException(DioException e) {
    final res = e.response;
    final status = res?.statusCode;

    if (e.type == DioExceptionType.cancel) {
      return ApiException.cancelled(message: 'Request cancelled');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.timeout(message: 'Request timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException.network(message: 'Network error');
    }

    if (status != null) {
      final data = res?.data;
      switch (status) {
        case 400:
          return ApiException.badRequest(
              message: _extractMessage(data), data: data);
        case 401:
          return ApiException.unauthorized(
              message: _extractMessage(data), data: data);
        case 403:
          return ApiException.forbidden(
              message: _extractMessage(data), data: data);
        case 404:
          return ApiException.notFound(
              message: _extractMessage(data), data: data);
        case 409:
          return ApiException.conflict(
              message: _extractMessage(data), data: data);
        default:
          if (status >= 500) {
            return ApiException.server(
                message: _extractMessage(data), data: data, statusCode: status);
          }
          return ApiException.unknown(
              message: _extractMessage(data), data: data, statusCode: status);
      }
    }

    return ApiException.unknown(message: e.message ?? 'Unknown error');
  }

  String _extractMessage(Object? data) {
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return 'Request failed';
  }
}
