import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/external_url_opener.dart';

class PdfViewerWidget extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerWidget({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late PdfViewerController _pdfViewerController;
  // Меняем ключ, чтобы пересоздать SfPdfViewer при повторе загрузки.
  Key _viewerKey = UniqueKey();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _retry() {
    setState(() {
      _viewerKey = UniqueKey();
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _totalPages = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;
    final isReady = !hasError && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isReady && _totalPages > 0)
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
          if (isReady) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _pdfViewerController.zoomLevel += 0.25,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: isReady && _totalPages > 0
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
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          widget.pdfUrl,
          key: _viewerKey,
          controller: _pdfViewerController,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            if (!mounted) return;
            setState(() {
              _totalPages = details.document.pages.count;
              _isLoading = false;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            if (!mounted) return;
            setState(() => _currentPage = details.newPageNumber);
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = details.description.isNotEmpty
                  ? details.description
                  : 'Не удалось отобразить документ';
            });
          },
        ),
        if (_isLoading)
          Container(
            color: AppColors.background,
            child: const Center(child: CircularProgressIndicator()),
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
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openExternalUrl(widget.pdfUrl),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text(
                    kIsWeb ? 'Открыть в новой вкладке' : 'Открыть в браузере',
                  ),
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
