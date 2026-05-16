import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';

enum _PdfMode { loading, native, webview, error }

class PdfViewerWidget extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerWidget({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _pdfRendering = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;
  _PdfMode _mode = _PdfMode.loading;

  bool _webviewLoading = true;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final url = widget.pdfUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _mode = _PdfMode.error;
        _errorMessage = 'Ссылка на документ пуста';
      });
      return;
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 45),
          followRedirects: true,
          maxRedirects: 10,
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 400,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Accept': 'application/pdf,application/octet-stream,*/*',
          },
        ),
      );

      final response = await dio.get<List<int>>(url);
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw Exception('Пустой ответ');
      }

      if (!mounted) return;
      setState(() {
        _pdfBytes = Uint8List.fromList(data);
        _mode = _PdfMode.native;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mode = _PdfMode.webview;
        _webviewLoading = true;
      });
    }
  }

  String get _gviewUrl =>
      'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.pdfUrl)}';

  Future<void> _openInBrowser() async {
    try {
      await InAppBrowser().openUrlRequest(
        urlRequest: URLRequest(url: WebUri(widget.pdfUrl)),
      );
    } catch (_) {}
  }

  void _retryNative() {
    setState(() {
      _mode = _PdfMode.loading;
      _errorMessage = null;
      _pdfBytes = null;
      _pdfRendering = true;
    });
    _loadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_mode == _PdfMode.native && _totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_mode == _PdfMode.native && _pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _pdfViewerController.zoomLevel += 0.25,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Открыть в браузере',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
          _mode == _PdfMode.native && _pdfBytes != null && _totalPages > 0
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'prev_page',
                      mini: true,
                      onPressed: _currentPage > 1
                          ? () => _pdfViewerController.previousPage()
                          : null,
                      child: const Icon(Icons.arrow_upward),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'next_page',
                      mini: true,
                      onPressed: _currentPage < _totalPages
                          ? () => _pdfViewerController.nextPage()
                          : null,
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ],
                )
              : null,
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _PdfMode.loading:
        return _buildLoading('Загрузка PDF...');
      case _PdfMode.error:
        return _buildError(_errorMessage ?? 'Не удалось открыть документ');
      case _PdfMode.native:
        return _buildNative();
      case _PdfMode.webview:
        return _buildWebView();
    }
  }

  Widget _buildLoading(String text) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              text,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNative() {
    return Stack(
      children: [
        SfPdfViewer.memory(
          _pdfBytes!,
          controller: _pdfViewerController,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            if (!mounted) return;
            setState(() {
              _totalPages = details.document.pages.count;
              _pdfRendering = false;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            if (!mounted) return;
            setState(() {
              _currentPage = details.newPageNumber;
            });
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            if (!mounted) return;
            setState(() {
              _mode = _PdfMode.webview;
              _webviewLoading = true;
            });
          },
        ),
        if (_pdfRendering)
          Container(
            color: AppColors.background.withValues(alpha: 0.8),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_gviewUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useHybridComposition: true,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            userAgent:
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          ),
          onWebViewCreated: (c) => _webViewController = c,
          onLoadStop: (_, __) {
            if (!mounted) return;
            setState(() => _webviewLoading = false);
          },
          onProgressChanged: (_, progress) {
            if (progress >= 70 && _webviewLoading) {
              if (!mounted) return;
              setState(() => _webviewLoading = false);
            }
          },
          onReceivedError: (_, request, error) {
            if (!(request.isForMainFrame ?? false)) return;
            if (!mounted) return;
            setState(() {
              _mode = _PdfMode.error;
              _errorMessage =
                  'Не удалось загрузить документ ни напрямую, ни через '
                  'просмотрщик Google. ${error.description}';
            });
          },
        ),
        if (_webviewLoading)
          Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Открываем через Google Docs Viewer...'),
                ],
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.extended(
            heroTag: 'retry_native_pdf',
            onPressed: _retryNative,
            icon: const Icon(Icons.refresh),
            label: const Text('Прямая загрузка'),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Не удалось открыть PDF',
              style: AppTypography.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryNative,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
                OutlinedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Открыть в браузере'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
