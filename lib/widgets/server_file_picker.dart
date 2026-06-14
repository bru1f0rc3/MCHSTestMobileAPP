import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/models/storage_file_model.dart';
import 'package:mchs_mobile_app/services/storage_service.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';

/// Открывает обзор серверного хранилища и возвращает выбранный файл.
///
/// Показывает ТОЛЬКО файлы из папки хранилища на сервере
/// (videos/ или documents/) — доступа к файловой системе устройства нет.
Future<StorageFileModel?> showServerFilePicker(
  BuildContext context,
  WidgetRef ref,
  StorageFileType type,
) {
  return showModalBottomSheet<StorageFileModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ServerFilePickerSheet(type: type, parentRef: ref),
  );
}

class _ServerFilePickerSheet extends StatefulWidget {
  final StorageFileType type;
  final WidgetRef parentRef;

  const _ServerFilePickerSheet({required this.type, required this.parentRef});

  @override
  State<_ServerFilePickerSheet> createState() => _ServerFilePickerSheetState();
}

class _ServerFilePickerSheetState extends State<_ServerFilePickerSheet> {
  late Future<List<StorageFileModel>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  bool get _isVideo => widget.type == StorageFileType.video;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.parentRef.read(storageServiceProvider).browse(widget.type);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StorageFileModel> _applyFilter(List<StorageFileModel> files) {
    if (_query.trim().isEmpty) return files;
    final q = _query.trim().toLowerCase();
    return files
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isVideo ? 'Видео на сервере' : 'Документы на сервере';
    final folder = _isVideo ? 'videos/' : 'documents/';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    _isVideo
                        ? Icons.video_library_outlined
                        : Icons.picture_as_pdf_outlined,
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.heading4.copyWith(
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Папка хранилища $folder',
                          style: AppTypography.caption.copyWith(
                            color: context.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Обновить',
                    onPressed: () => setState(_load),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Поиск по имени файла',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Очистить',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<StorageFileModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildMessage(
            icon: Icons.error_outline,
            title: 'Не удалось загрузить список',
            message: 'Проверьте подключение к серверу и попробуйте снова.',
          );
        }

        final allFiles = snapshot.data ?? [];
        if (allFiles.isEmpty) {
          return _buildMessage(
            icon: Icons.folder_off_outlined,
            title: 'Папка пуста',
            message: _isVideo
                ? 'Добавьте видеофайлы в папку videos/ на сервере.'
                : 'Добавьте PDF-файлы в папку documents/ на сервере.',
          );
        }

        final files = _applyFilter(allFiles);
        if (files.isEmpty) {
          return _buildMessage(
            icon: Icons.search_off_rounded,
            title: 'Ничего не найдено',
            message: 'По запросу «$_query» файлов нет.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: files.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: context.primaryColor.withValues(alpha: 0.10),
                child: Icon(
                  _isVideo ? Icons.movie_outlined : Icons.description_outlined,
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body1.copyWith(
                  color: context.textPrimaryColor,
                ),
              ),
              subtitle: Text(
                [
                  file.extension.toUpperCase(),
                  if (file.readableSize.isNotEmpty) file.readableSize,
                ].join(' · '),
                style: AppTypography.caption.copyWith(
                  color: context.textTertiaryColor,
                ),
              ),
              onTap: () => Navigator.pop(context, file),
            );
          },
        );
      },
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.textTertiaryColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.body1.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
