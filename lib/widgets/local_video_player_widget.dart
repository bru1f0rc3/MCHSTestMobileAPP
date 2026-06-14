import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mchs_mobile_app/services/storage_service.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';

/// Встроенный нативный видеоплеер для лекций.
///
/// Воспроизводит видео из локального хранилища сервера (или прямую ссылку)
/// средствами video_player + chewie. Встроенная кнопка разворачивает плеер
/// на весь экран — отдельный webview больше не используется.
class LocalVideoPlayer extends StatefulWidget {
  /// Сохранённое в лекции значение: относительный путь в хранилище
  /// (например "videos/intro.mp4") либо абсолютная ссылка.
  final String source;

  const LocalVideoPlayer({super.key, required this.source});

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url = StorageUrls.fileUrl(widget.source);
    if (url.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ссылка на видео пуста';
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: Colors.white38,
          backgroundColor: Colors.white24,
        ),
        errorBuilder: (context, errorMessage) =>
            _buildError(errorMessage, dark: true),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      _videoController?.dispose();
      _videoController = null;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить видео';
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;
    await _initialize();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null || _chewieController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildError(_errorMessage ?? 'Не удалось загрузить видео'),
      );
    }

    return AspectRatio(
      aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildError(String message, {bool dark = false}) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTypography.caption.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
