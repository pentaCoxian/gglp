import 'package:dio/dio.dart';

import '../../core/logger.dart';
import 'host.dart';
import 'misskey_errors.dart';

/// Host-aware Misskey HTTP client.
///
/// All Misskey REST endpoints are POST-only with the access token sent in
/// the request body as `i`. We keep one `Dio` per host so connection pools
/// are reused and per-host timeouts can be tuned later.
class MisskeyHttpClient {
  final MisskeyHost host;
  final String? token;
  final Dio _dio;
  final _log = const Log('MisskeyHttp');

  MisskeyHttpClient({
    required this.host,
    this.token,
    Dio? dio,
  }) : _dio = dio ?? _buildDio(host) {
    _dio.interceptors.add(_RetryInterceptor(_log));
  }

  static Dio _buildDio(MisskeyHost host) {
    return Dio(BaseOptions(
      baseUrl: 'https://${host.value}/api/',
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {
        'User-Agent': 'GGLP (+https://github.com/pentaCoxian/gglp)',
        'Accept': 'application/json',
      },
    ));
  }

  /// Call any Misskey API endpoint with the access token auto-injected.
  ///
  /// `path` is the part after `/api/` (e.g. `notes/timeline`, `meta`).
  /// `params` is merged with `{i: token}` if a token is set.
  Future<dynamic> call(
    String path, {
    Map<String, dynamic>? params,
    bool requireToken = false,
  }) async {
    if (requireToken && (token == null || token!.isEmpty)) {
      throw const MisskeyApiError(
        code: 'CREDENTIAL_REQUIRED',
        message: 'No access token configured for this host',
      );
    }
    final body = <String, dynamic>{
      ...?params,
      if (token != null && token!.isNotEmpty) 'i': token,
    };
    try {
      final res = await _dio.post<dynamic>(path, data: body);
      return res.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw MisskeyNetworkError('Unexpected: $e', e);
    }
  }

  /// GET a non-`/api/` path on the same host — e.g. the `/url`
  /// summaly proxy that powers link-preview cards. No token is sent
  /// (these routes are anonymous).
  Future<dynamic> getPath(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        'https://${host.value}/$path',
        queryParameters: query,
      );
      return res.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw MisskeyNetworkError('Unexpected: $e', e);
    }
  }

  /// Multipart upload for `drive/files/create`.
  ///
  /// Misskey's drive endpoint expects a real multipart/form-data
  /// request with the access token in the `i` form field rather than
  /// the JSON body. We can't share [call]'s code path because dio
  /// switches its serializer based on `data`'s type.
  Future<Map<String, dynamic>> upload({
    required String path,
    required MultipartFile file,
    Map<String, String>? extraFields,
  }) async {
    if (token == null || token!.isEmpty) {
      throw const MisskeyApiError(
        code: 'CREDENTIAL_REQUIRED',
        message: 'No access token configured for this host',
      );
    }
    final form = FormData.fromMap({
      'i': token,
      'file': file,
      if (extraFields != null) ...extraFields,
    });
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw MisskeyUnknownError(httpStatus: res.statusCode, body: '$data');
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw MisskeyNetworkError('Unexpected: $e', e);
    }
  }

  MisskeyError _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const MisskeyTimeoutError();
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return MisskeyNetworkError(e.message ?? 'Connection failed', e);
      case DioExceptionType.cancel:
        return MisskeyNetworkError('Cancelled', e);
      case DioExceptionType.badCertificate:
        return MisskeyNetworkError('Bad TLS certificate', e);
      case DioExceptionType.badResponse:
        // Try to parse Misskey error envelope.
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final err = data['error'];
          if (err is Map<String, dynamic>) {
            return MisskeyApiError(
              httpStatus: status,
              code: err['code']?.toString() ?? 'UNKNOWN',
              message: err['message']?.toString() ?? '',
              id: err['id']?.toString(),
              kind: err['kind']?.toString(),
              raw: err,
            );
          }
        }
        return MisskeyUnknownError(httpStatus: status, body: '${e.response?.data}');
    }
  }
}

/// Retry transient 5xx and timeouts up to 2 times with backoff.
/// Authentication and 4xx errors are NOT retried — they need user action.
class _RetryInterceptor extends Interceptor {
  final Log log;
  _RetryInterceptor(this.log);

  static const _maxRetries = 2;
  static const _baseDelay = Duration(milliseconds: 400);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (!_shouldRetry(err) || retryCount >= _maxRetries) {
      return handler.next(err);
    }
    final delay = _baseDelay * (1 << retryCount);
    log.warn(
      'retry ${retryCount + 1}/$_maxRetries after ${delay.inMilliseconds}ms: '
      '${err.requestOptions.path} (${err.type})',
    );
    await Future<void>.delayed(delay);
    err.requestOptions.extra['retryCount'] = retryCount + 1;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: err.requestOptions.baseUrl,
        connectTimeout: err.requestOptions.connectTimeout,
        sendTimeout: err.requestOptions.sendTimeout,
        receiveTimeout: err.requestOptions.receiveTimeout,
        contentType: err.requestOptions.contentType,
        responseType: err.requestOptions.responseType,
        headers: err.requestOptions.headers,
      ));
      final response = await dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = e.response?.statusCode ?? 0;
    return status >= 500 && status < 600;
  }
}
