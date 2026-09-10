/// Domain errors mapped from Misskey HTTP / network failures.
///
/// Misskey returns errors as
///   { "error": { "id": "uuid", "code": "STR", "message": "...", "kind": "client|server" } }
///
/// We collapse network errors and unknown shapes into the same sealed type
/// so UI/repositories can pattern-match without reaching for raw Dio types.
sealed class MisskeyError implements Exception {
  const MisskeyError();
}

class MisskeyApiError extends MisskeyError {
  final int? httpStatus;
  final String code;
  final String message;
  final String? id;
  final String? kind;
  final Map<String, dynamic>? raw;

  const MisskeyApiError({
    required this.code,
    required this.message,
    this.httpStatus,
    this.id,
    this.kind,
    this.raw,
  });

  bool get isAuthError =>
      code == 'AUTHENTICATION_FAILED' ||
      code == 'NO_CREDENTIALS' ||
      code == 'CREDENTIAL_REQUIRED' ||
      httpStatus == 401;

  bool get isRateLimited => code == 'RATE_LIMIT_EXCEEDED' || httpStatus == 429;

  @override
  String toString() => 'MisskeyApiError($httpStatus $code: $message)';
}

class MisskeyNetworkError extends MisskeyError {
  final String message;
  final Object? cause;
  const MisskeyNetworkError(this.message, [this.cause]);
  @override
  String toString() => 'MisskeyNetworkError($message)';
}

class MisskeyTimeoutError extends MisskeyError {
  const MisskeyTimeoutError();
  @override
  String toString() => 'MisskeyTimeoutError';
}

class MisskeyUnknownError extends MisskeyError {
  final int? httpStatus;
  final String? body;
  const MisskeyUnknownError({this.httpStatus, this.body});
  @override
  String toString() => 'MisskeyUnknownError($httpStatus, $body)';
}
