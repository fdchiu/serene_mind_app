import 'package:flutter/foundation.dart';

/// Rewrites direct Pixabay CDN URLs to use a relay endpoint that fetches
/// the audio on the server side (avoids client-side 403 hotlink errors).
///
/// The relay contract:
///   GET /audio/pixabay?url=<full cdn.pixabay.com download url>
///   - No auth
///   - Returns raw audio bytes with caching headers and X-Proxy-Cache
///
/// Configure the base via a compile-time environment value:
///   --dart-define=PIXABAY_PROXY_BASE=https://yourdomain
class PixabayProxyClient {
  PixabayProxyClient({
    String? proxyBaseUrl,
  }) : _base = _normalizeBase(proxyBaseUrl ?? const String.fromEnvironment('PIXABAY_PROXY_BASE'));

  final Uri? _base;

  /// Returns the proxied URI if the input is a cdn.pixabay.com URL and the
  /// proxy base is configured; otherwise returns [original].
  Uri rewriteIfPixabay(Uri original) {
    if (_base == null) return original;
    if (!_isPixabayCdn(original)) return original;
    return _base!.replace(
      path: '/audio/pixabay',
      queryParameters: {'url': original.toString()},
    );
  }

  static bool _isPixabayCdn(Uri uri) {
    return uri.host.toLowerCase().endsWith('pixabay.com');
  }

  static Uri? _normalizeBase(String raw) {
    if (raw.isEmpty) return null;
    try {
      final uri = Uri.parse(raw);
      if (!uri.hasScheme || !uri.hasAuthority) return null;
      return uri;
    } catch (_) {
      return null;
    }
  }
}
