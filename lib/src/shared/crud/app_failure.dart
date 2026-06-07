/// Structured user-safe failure information for CRUD flows.
///
/// Technical exceptions stay in [cause] / [stackTrace] for diagnostics while
/// [message] remains suitable for UI display.
enum AppFailureCode {
  validation,
  duplicate,
  notFound,
  conflict,
  referenced,
  permissionDenied,
  network,
  fileSystem,
  database,
  cancelled,
  unknown,
}

class AppFailure {
  const AppFailure({
    required this.code,
    required this.message,
    this.field,
    this.cause,
    this.stackTrace,
  });

  final AppFailureCode code;
  final String message;
  final String? field;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isFieldFailure => field != null;

  AppFailure copyWith({
    AppFailureCode? code,
    String? message,
    String? field,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppFailure(
      code: code ?? this.code,
      message: message ?? this.message,
      field: field ?? this.field,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() =>
      'AppFailure(code: $code, message: $message, field: $field)';
}
