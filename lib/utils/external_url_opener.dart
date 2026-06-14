/// Открывает URL «снаружи» приложения:
/// - на вебе — в новой вкладке браузера;
/// - на устройствах — во встроенном браузере (InAppBrowser).
///
/// Открытие в новой вкладке не подчиняется запретам `X-Frame-Options`,
/// поэтому работает даже для сайтов, запрещающих встраивание в iframe.
library;

export 'external_url_opener_io.dart'
    if (dart.library.html) 'external_url_opener_web.dart';
