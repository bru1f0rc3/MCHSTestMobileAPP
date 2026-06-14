import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Открывает [url] во встроенном браузере устройства.
Future<void> openExternalUrl(String url) async {
  try {
    await InAppBrowser().openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  } catch (_) {}
}
