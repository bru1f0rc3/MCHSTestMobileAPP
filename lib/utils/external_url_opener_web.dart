// ignore: deprecated_member_use
import 'dart:html' as html;

/// Открывает [url] в новой вкладке браузера.
///
/// Новая вкладка — top-level навигация, на неё не действуют ни CORS,
/// ни `X-Frame-Options`, поэтому PDF и видео открываются всегда.
Future<void> openExternalUrl(String url) async {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}
