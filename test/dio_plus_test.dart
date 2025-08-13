import 'package:dio_toolkit/dio_toolkit.dart';
import 'package:test/test.dart';

void main() {
  test('client constructs with baseUrl', () {
    final client =
        DioToolkitClient.withDefaults(baseUrl: 'https://example.com');
    expect(client.dio.options.baseUrl, 'https://example.com');
  });
}
