import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/services/storage_service.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/widgets/server_file_picker.dart';

/// Поле выбора файла из серверного хранилища.
///
/// «Загрузить» — заливает файл с устройства в папку хранилища на сервере.
/// «Обзор» — открывает список уже лежащих на сервере файлов (не с устройства).
/// Выбранный/загруженный относительный путь сохраняется в [controller].
class StorageFileField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final StorageFileType type;
  final String label;
  final IconData icon;

  const StorageFileField({
    super.key,
    required this.controller,
    required this.type,
    required this.label,
    required this.icon,
  });

  @override
  ConsumerState<StorageFileField> createState() => _StorageFileFieldState();
}

class _StorageFileFieldState extends ConsumerState<StorageFileField> {
  bool _isUploading = false;
  double _progress = 0;

  String _displayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final segments = trimmed.replaceAll('\\', '/').split('/');
    return segments.isEmpty ? trimmed : segments.last;
  }

  Future<void> _browse() async {
    final file = await showServerFilePicker(context, ref, widget.type);
    if (file != null) widget.controller.text = file.path;
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.type.allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    // На web обращение к picked.path бросает исключение — там работаем только с bytes.
    final filePath = kIsWeb ? null : picked.path;
    if (filePath == null && picked.bytes == null) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Не удалось прочитать файл');
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    try {
      final uploaded = await ref
          .read(storageServiceProvider)
          .upload(
            widget.type,
            fileName: picked.name,
            filePath: filePath,
            bytes: picked.bytes,
            onProgress: (sent, total) {
              if (total > 0 && mounted) {
                setState(() => _progress = sent / total);
              }
            },
          );
      if (!mounted) return;
      if (uploaded != null) {
        widget.controller.text = uploaded.path;
        ErrorHandler.showSuccessSnackBar(context, 'Файл загружен на сервер');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final fileName = _displayName(value.text);
        final hasValue = fileName.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: hasValue
                        ? context.primaryColor
                        : context.textTertiaryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasValue ? fileName : 'Файл не выбран',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: hasValue
                            ? context.textPrimaryColor
                            : context.textTertiaryColor,
                      ),
                    ),
                  ),
                  if (hasValue && !_isUploading)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Очистить',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => widget.controller.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_isUploading)
              _buildUploadingRow()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _upload,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Загрузить'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _browse,
                      icon: const Icon(Icons.folder_open_outlined, size: 18),
                      label: const Text('Обзор'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildUploadingRow() {
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _progress > 0 ? _progress : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _progress > 0 ? 'Загрузка… $percent%' : 'Загрузка…',
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
