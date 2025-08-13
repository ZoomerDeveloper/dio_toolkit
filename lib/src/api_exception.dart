sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? data;

  ApiException(this.message, {this.statusCode, this.data});

  factory ApiException.network({String message = 'Network error'}) =>
      _Network(message);
  factory ApiException.timeout({String message = 'Timeout'}) =>
      _Timeout(message);
  factory ApiException.badRequest(
          {String message = 'Bad request', Object? data}) =>
      _BadRequest(message, data: data, statusCode: 400);
  factory ApiException.unauthorized(
          {String message = 'Unauthorized', Object? data}) =>
      _Unauthorized(message, data: data, statusCode: 401);
  factory ApiException.forbidden(
          {String message = 'Forbidden', Object? data}) =>
      _Forbidden(message, data: data, statusCode: 403);
  factory ApiException.notFound({String message = 'Not found', Object? data}) =>
      _NotFound(message, data: data, statusCode: 404);
  factory ApiException.conflict({String message = 'Conflict', Object? data}) =>
      _Conflict(message, data: data, statusCode: 409);
  factory ApiException.server(
          {String message = 'Server error', Object? data, int? statusCode}) =>
      _Server(message, data: data, statusCode: statusCode);
  factory ApiException.cancelled({String message = 'Cancelled'}) =>
      _Cancelled(message);
  factory ApiException.unknown(
          {String message = 'Unknown error', Object? data, int? statusCode}) =>
      _Unknown(message, data: data, statusCode: statusCode);
}

class _Network extends ApiException {
  _Network(super.message) : super(statusCode: null);
}

class _Timeout extends ApiException {
  _Timeout(super.message) : super(statusCode: null);
}

class _BadRequest extends ApiException {
  _BadRequest(super.message, {super.data, super.statusCode});
}

class _Unauthorized extends ApiException {
  _Unauthorized(super.message, {super.data, super.statusCode});
}

class _Forbidden extends ApiException {
  _Forbidden(super.message, {super.data, super.statusCode});
}

class _NotFound extends ApiException {
  _NotFound(super.message, {super.data, super.statusCode});
}

class _Conflict extends ApiException {
  _Conflict(super.message, {super.data, super.statusCode});
}

class _Server extends ApiException {
  _Server(super.message, {super.data, super.statusCode});
}

class _Cancelled extends ApiException {
  _Cancelled(super.message);
}

class _Unknown extends ApiException {
  _Unknown(super.message, {super.data, super.statusCode});
}
