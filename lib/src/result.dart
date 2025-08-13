import 'api_exception.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException e) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    return failure((self as Failure<T>).error);
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final ApiException error;
  const Failure(this.error);
}
