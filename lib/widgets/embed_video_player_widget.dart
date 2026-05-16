import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';

class EmbedVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;

  const EmbedVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<EmbedVideoPlayerWidget> createState() => _EmbedVideoPlayerWidgetState();
}

class _EmbedVideoPlayerWidgetState extends State<EmbedVideoPlayerWidget> {
  static const Duration _loadingTimeout = Duration(seconds: 15);

  String? _embedUrl;
  bool _isYouTube = false;
  String? _errorMessage;
  bool _isLoading = true;
  bool _firstFrameSeen = false;
  Timer? _timeoutTimer;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      _errorMessage = 'Ссылка на видео пуста';
      return;
    }
    final embed = VideoUrlConverter.toEmbedUrl(url);
    if (embed == null) {
      _errorMessage = 'Не удалось распознать ссылку на видео';
      return;
    }
    _embedUrl = embed;
    _isYouTube = embed.contains('youtube');
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_loadingTimeout, () {
      if (!mounted) return;
      if (_isLoading && !_firstFrameSeen) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isYouTube
              ? 'Видео не загрузилось за ${_loadingTimeout.inSeconds} с. '
                  'YouTube часто недоступен из российских сетей — '
                  'попробуйте открыть в браузере или используйте VPN.'
              : 'Видео не загрузилось за ${_loadingTimeout.inSeconds} секунд. '
                  'Возможно хостинг недоступен из вашей сети.';
        });
      }
    });
  }

  void _markLoaded() {
    if (!mounted) return;
    if (_isLoading) {
      setState(() => _isLoading = false);
    }
    _firstFrameSeen = true;
    _timeoutTimer?.cancel();
  }

  Future<void> _openExternally() async {
    try {
      await InAppBrowser().openUrlRequest(
        urlRequest: URLRequest(url: WebUri(widget.videoUrl)),
      );
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _firstFrameSeen = false;
      _errorMessage = null;
    });
    _startTimeout();
    _webViewController?.reload();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Открыть в браузере',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildError(_errorMessage!)
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_embedUrl!)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    iframeAllowFullscreen: true,
                    transparentBackground: true,
                    useHybridComposition: true,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    mixedContentMode:
                        MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    userAgent:
                        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStop: (_, __) => _markLoaded(),
                  onProgressChanged: (_, progress) {
                    if (progress >= 70) _markLoaded();
                  },
                  onReceivedError: (_, request, error) {
                    if (request.isForMainFrame ?? false) {
                      if (!mounted) return;
                      _timeoutTimer?.cancel();
                      setState(() {
                        _isLoading = false;
                        _errorMessage =
                            'Ошибка загрузки: ${error.description}';
                      });
                    }
                  },
                  onReceivedHttpError: (_, request, response) {
                    if ((request.isForMainFrame ?? false) &&
                        (response.statusCode ?? 0) >= 400) {
                      if (!mounted) return;
                      _timeoutTimer?.cancel();
                      setState(() {
                        _isLoading = false;
                        _errorMessage =
                            'HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}';
                      });
                    }
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Не удалось открыть видео',
                style: AppTypography.heading4.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.body2.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (_embedUrl != null)
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: _openExternally,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Открыть в браузере'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoUrlConverter {
  VideoUrlConverter._();

  static String? toEmbedUrl(String url) {
    final youtubeId = _extractYouTubeId(url);
    if (youtubeId != null) {
      return 'https://www.youtube-nocookie.com/embed/$youtubeId'
          '?autoplay=1&playsinline=1&rel=0';
    }

    final rutubeId = _extractRuTubeId(url);
    if (rutubeId != null) {
      return 'https://rutube.ru/play/embed/$rutubeId';
    }

    final vkParts = _extractVkVideoParts(url);
    if (vkParts != null) {
      return 'https://vk.com/video_ext.php?oid=${vkParts.$1}&id=${vkParts.$2}&autoplay=1';
    }

    final vimeoId = _extractVimeoId(url);
    if (vimeoId != null) {
      return 'https://player.vimeo.com/video/$vimeoId?autoplay=1';
    }

    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    return null;
  }

  static String? _extractYouTubeId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com|m\.youtube\.com)/watch\?(?:.*&)?v=([\w-]+)'),
      RegExp(r'youtu\.be/([\w-]+)'),
      RegExp(r'youtube\.com/embed/([\w-]+)'),
      RegExp(r'youtube\.com/shorts/([\w-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static String? _extractRuTubeId(String url) {
    final m = RegExp(
      r'rutube\.ru/(?:video|play/embed)/([a-zA-Z0-9]+)',
    ).firstMatch(url);
    return m?.group(1);
  }

  static (String, String)? _extractVkVideoParts(String url) {
    final pathMatch = RegExp(r'/video(-?\d+)_(\d+)').firstMatch(url);
    if (pathMatch != null) {
      return (pathMatch.group(1)!, pathMatch.group(2)!);
    }
    final oidMatch = RegExp(r'oid=(-?\d+)').firstMatch(url);
    final idMatch = RegExp(r'(?:^|[?&])id=(\d+)').firstMatch(url);
    if (oidMatch != null && idMatch != null) {
      return (oidMatch.group(1)!, idMatch.group(1)!);
    }
    return null;
  }

  static String? _extractVimeoId(String url) {
    final m = RegExp(
      r'(?:vimeo\.com|player\.vimeo\.com/video)/(\d+)',
    ).firstMatch(url);
    return m?.group(1);
  }
}
