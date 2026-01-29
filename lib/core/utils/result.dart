/// Result pattern for handling success and error states
///
/// This pattern is used throughout the application to handle operations
/// that can fail without throwing exceptions.
abstract class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.error(String message) = Error<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  });

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  }) =>
      success(data);
}

class Error<T> extends Result<T> {
  final String message;
  const Error(this.message);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  }) =>
      error(message);
}
