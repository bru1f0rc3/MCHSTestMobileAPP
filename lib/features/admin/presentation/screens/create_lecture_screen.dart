import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/core/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/features/lectures/data/services/lecture_service.dart';
import 'package:mchs_mobile_app/features/lectures/data/models/lecture_model.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';

class CreateLectureScreen extends ConsumerStatefulWidget {
  const CreateLectureScreen({super.key});

  @override
  ConsumerState<CreateLectureScreen> createState() => _CreateLectureScreenState();
}

class _CreateLectureScreenState extends ConsumerState<CreateLectureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _videoPathController = TextEditingController();
  final _documentPathController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _videoPathController.dispose();
    _documentPathController.dispose();
    super.dispose();
  }

  Future<void> _createLecture() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(lectureServiceProvider);
      final response = await service.create(CreateLectureRequest(
        title: _titleController.text.trim(),
        textContent: _contentController.text.trim().isEmpty 
            ? null 
            : _contentController.text.trim(),
        videoPath: _videoPathController.text.trim().isEmpty
            ? null
            : _videoPathController.text.trim(),
        documentPath: _documentPathController.text.trim().isEmpty
            ? null
            : _documentPathController.text.trim(),
      ));

      if (response.success) {
        refreshAllLectureProviders(ref);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Лекция успешно создана');
          context.pop(true);
        }
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, response.message ?? 'Ошибка создания лекции');
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      return await ErrorHandler.showConfirmDialog(
        context,
        title: 'Отменить создание?',
        message: 'Вы уверены? Все введенные данные будут потеряны.',
        confirmText: 'Отменить',
        isDangerous: true,
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) context.pop();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Создать лекцию')),
        body: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  color: AppColors.info.withOpacity(0.1),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.book, color: AppColors.info, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Новая лекция', style: AppTypography.body1.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Заполните информацию о лекции', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _titleController,
                  label: 'Название лекции *',
                  hint: 'Введите название',
                  prefixIcon: Icons.title,
                  validator: (v) => Validators.title(v, 'Название лекции'),
                ),
                const SizedBox(height: 16),
                Text('Содержание лекции', style: AppTypography.body2.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Введите текст лекции...',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  validator: (v) => Validators.description(v, maxLength: 50000),
                ),
                const SizedBox(height: 24),
                Text('Медиа материалы (необязательно)', style: AppTypography.heading4.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(controller: _videoPathController, label: 'Ссылка на видео', hint: 'https://example.com/video.mp4', prefixIcon: Icons.video_library),
                const SizedBox(height: 16),
                CustomTextField(controller: _documentPathController, label: 'Ссылка на документ (PDF)', hint: 'https://example.com/document.pdf', prefixIcon: Icons.picture_as_pdf),
                const SizedBox(height: 32),
                CustomButton(text: 'Создать лекцию', icon: Icons.check, isLoading: _isLoading, onPressed: _isLoading ? null : _createLecture),
                const SizedBox(height: 16),
                CustomButton(text: 'Отмена', isOutlined: true, onPressed: () async { if (await _onWillPop()) context.pop(); }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
