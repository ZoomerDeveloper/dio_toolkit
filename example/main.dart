import 'package:dio_toolkit/dio_toolkit.dart';

// Пример модели под json_serializable
class User {
  final int id;
  final String name;
  User({required this.id, required this.name});
  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as int, name: json['name'] as String);
}

Future<void> main() async {
  String? _accessToken = 'ACCESS_TOKEN';
  String? _refreshToken = 'REFRESH_TOKEN';

  final cache = CacheStore();

  final client = DioToolkitClient.withDefaults(
    baseUrl: 'https://api.example.com',
    tokenProvider: () async => _accessToken,
    tokenRefresher: () async {
      // здесь делаем запрос рефреша
      // final res = await dio.post('/auth/refresh', data: {'refresh_token': _refreshToken});
      // return RefreshTokens(accessToken: res.data['access'], refreshToken: res.data['refresh']);
      // Для примера вернём фиктивные значения:
      return const RefreshTokens(
        accessToken: 'NEW_ACCESS',
        refreshToken: 'NEW_REFRESH',
      );
    },
    onTokensUpdated: (tokens) {
      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
    },
    isRefreshRequest: (req) => req.path.contains('/auth/refresh'),
    cacheStore: cache,
    enableLogging: true,
  );

  // GET с кэшем на 60 секунд
  final res = await client.get<List<User>>(
    '/users',
    extra: CacheOptions(maxAge: const Duration(seconds: 60)).toExtra(),
    decoder: (data) {
      final list = (data as List).cast<Map<String, dynamic>>();
      return list.map(User.fromJson).toList();
    },
  );

  res.when(
    success: (users) => print('Loaded users: ${users.length}'),
    failure: (e) => print('Error: ${e.message}'),
  );
}
