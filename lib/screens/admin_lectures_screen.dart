import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/services/lecture_service.dart';
import 'package:mchs_mobile_app/models/lecture_model.dart';

class AdminLecturesScreen extends ConsumerStatefulWidget {
  const AdminLecturesScreen({super.key});

  @override
  ConsumerState<AdminLecturesScreen> createState() =>
      _AdminLecturesScreenState();
}

class _AdminLecturesScreenState extends ConsumerState<AdminLecturesScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final lecturesAsync = ref.watch(lecturesProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Лекции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
            onPressed: () => _refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Создать лекцию',
            onPressed: () => _navigateToCreate(),
          ),
        ],
      ),
      body: lecturesAsync.when(
        data: (lectures) => _buildLecturesList(lectures),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: ErrorHandler.getErrorMessage(error),
          onRetry: _refresh,
        ),
      ),
    );
  }

  void _refresh() {
    refreshAllLectureProviders(ref);
  }

  void _navigateToCreate() {
    context.push('/admin/create-lecture').then((result) {
      if (result == true) _refresh();
    });
  }

  Widget _buildLecturesList(List<LectureModel> lectures) {
    if (lectures.isEmpty) {
      return EmptyState(
        icon: Icons.book_outlined,
        title: 'Нет лекций',
        message: 'Создайте первую лекцию для обучения',
        action: ElevatedButton.icon(
          onPressed: _navigateToCreate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Создать лекцию'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: lectures.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _buildLectureCard(lectures[index]),
      ),
    );
  }

  Widget _buildLectureCard(LectureModel lecture) {
    return CustomCard(
      onTap: () => context.push('/lecture-detail/${lecture.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.title,
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lecture.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(lecture.createdAt!),
                    style: AppTypography.caption.copyWith(
                      color: context.textTertiaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isProcessing,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: context.textTertiaryColor,
            ),
            onSelected: (value) => _handleMenuAction(value, lecture),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Просмотр'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Редактировать'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Удалить',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, LectureModel lecture) {
    switch (action) {
      case 'view':
        context.push('/lecture-detail/${lecture.id}');
        break;
      case 'edit':
        _showEditLectureDialog(lecture);
        break;
      case 'delete':
        _confirmDelete(lecture.id, lecture.title);
        break;
    }
  }

  void _showEditLectureDialog(LectureModel lecture) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: lecture.title);
    final contentController = TextEditingController(
      text: lecture.textContent ?? '',
    );
    final videoPathController = TextEditingController(
      text: lecture.videoPath ?? '',
    );
    final documentPathController = TextEditingController(
      text: lecture.documentPath ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать лекцию'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: titleController,
                  label: 'Название',
                  hint: 'Введите название',
                  prefixIcon: Icons.title,
                  validator: (v) => Validators.title(v, 'Название'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Содержание',
                    hintText: 'Введите текст лекции',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) => Validators.description(v, maxLength: 10000),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: videoPathController,
                  label: 'Ссылка на видео',
                  hint: 'https://example.com/video.mp4',
                  prefixIcon: Icons.video_library,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: documentPathController,
                  label: 'Ссылка на документ (PDF)',
                  hint: 'https://example.com/document.pdf',
                  prefixIcon: Icons.picture_as_pdf,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => _saveEditedLecture(
              dialogContext,
              formKey,
              lecture.id,
              titleController,
              contentController,
              videoPathController,
              documentPathController,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEditedLecture(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    int lectureId,
    TextEditingController titleController,
    TextEditingController contentController,
    TextEditingController videoPathController,
    TextEditingController documentPathController,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(lectureServiceProvider);
      await service.update(
        lectureId,
        UpdateLectureRequest(
          title: titleController.text.trim(),
          textContent: contentController.text.trim(),
          videoPath: videoPathController.text.trim().isEmpty
              ? null
              : videoPathController.text.trim(),
          documentPath: documentPathController.text.trim().isEmpty
              ? null
              : documentPathController.text.trim(),
        ),
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Лекция успешно обновлена');
        refreshAllLectureProviders(ref);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDelete(int lectureId, String title) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: 'Удалить лекцию?',
      message:
          'Вы уверены, что хотите удалить лекцию "$title"?\n\nЭто также удалит все связанные тесты. Это действие нельзя отменить.',
      confirmText: 'Удалить',
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = ref.read(lectureServiceProvider);
      await service.delete(lectureId);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Лекция успешно удалена');
        refreshAllLectureProviders(ref);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
