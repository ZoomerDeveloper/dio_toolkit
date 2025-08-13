import 'package:dio/dio.dart';

class CacheOptions {
  static const extraKey = 'cache_options';
  final Duration maxAge;
  final bool forceRefresh;

  const CacheOptions(
      {this.maxAge = const Duration(minutes: 5), this.forceRefresh = false});

  Map<String, dynamic> toExtra() => {extraKey: this};
  static CacheOptions? fromExtra(Map<String, dynamic>? extra) {
    if (extra == null) return null;
    final v = extra[extraKey];
    return v is CacheOptions ? v : null;
  }
}

class CacheEntry {
  final dynamic data;
  final int statusCode;
  final Headers headers;
  final DateTime insertedAt;
  final Duration maxAge;

  CacheEntry({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.insertedAt,
    required this.maxAge,
  });

  bool get isExpired => DateTime.now().isAfter(insertedAt.add(maxAge));
}

class CacheStore {
  final Map<String, CacheEntry> _map = <String, CacheEntry>{};

  String keyFor(RequestOptions options) =>
      '${options.method.toUpperCase()} ${options.uri}';

  CacheEntry? get(String key) => _map[key];
  void set(String key, CacheEntry entry) => _map[key] = entry;
  void remove(String key) => _map.remove(key);
  void clear() => _map.clear();
}
