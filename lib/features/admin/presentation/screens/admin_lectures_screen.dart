import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/core/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/features/lectures/data/services/lecture_service.dart';
import 'package:mchs_mobile_app/features/lectures/data/models/lecture_model.dart';

class AdminLecturesScreen extends ConsumerStatefulWidget {
  const AdminLecturesScreen({super.key});

  @override
  ConsumerState<AdminLecturesScreen> createState() => _AdminLecturesScreenState();
}

class _AdminLecturesScreenState extends ConsumerState<AdminLecturesScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final lecturesAsync = ref.watch(lecturesProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Управление лекциями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => _refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать лекцию',
            onPressed: () => _navigateToCreate(),
          ),
        ],
      ),
      body: lecturesAsync.when(
        data: (lectures) => _buildLecturesList(lectures),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
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

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Ошибка загрузки', style: AppTypography.heading4.copyWith(color: AppColors.error)),
            const SizedBox(height: 8),
            Text(ErrorHandler.getErrorMessage(error), style: AppTypography.body2.copyWith(color: context.textSecondaryColor), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            CustomButton(text: 'Повторить', icon: Icons.refresh, onPressed: _refresh),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturesList(List<LectureModel> lectures) {
    if (lectures.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 80, color: context.textTertiaryColor),
              const SizedBox(height: 24),
              Text('Нет лекций', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Создайте новую лекцию для обучения', style: AppTypography.body2.copyWith(color: context.textSecondaryColor), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              CustomButton(text: 'Создать лекцию', icon: Icons.add, onPressed: _navigateToCreate),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: lectures.length,
        itemBuilder: (context, index) {
          final lecture = lectures[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildLectureCard(lecture),
          );
        },
      ),
    );
  }

  Widget _buildLectureCard(LectureModel lecture) {
    return CustomCard(
      onTap: () => context.push('/lecture-detail/${lecture.id}'),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.book, color: AppColors.info, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lecture.title, style: AppTypography.body1.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.w600)),
                if (lecture.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: context.textTertiaryColor),
                      const SizedBox(width: 4),
                      Text(_formatDate(lecture.createdAt!), style: AppTypography.caption.copyWith(color: context.textTertiaryColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isProcessing,
            onSelected: (value) => _handleMenuAction(value, lecture),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 12), Text('Просмотр')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Редактировать')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Удалить', style: TextStyle(color: AppColors.error))])),
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
    final contentController = TextEditingController(text: lecture.textContent ?? '');

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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => Validators.description(v, maxLength: 10000),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () => _saveEditedLecture(dialogContext, formKey, lecture.id, titleController, contentController),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEditedLecture(BuildContext dialogContext, GlobalKey<FormState> formKey, int lectureId, TextEditingController titleController, TextEditingController contentController) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(lectureServiceProvider);
      await service.update(lectureId, UpdateLectureRequest(title: titleController.text.trim(), textContent: contentController.text.trim()));
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
      message: 'Вы уверены, что хотите удалить лекцию "$title"?\n\nЭто также удалит все связанные тесты. Это действие нельзя отменить.',
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
