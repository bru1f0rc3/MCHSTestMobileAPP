import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/widgets/storage_file_field.dart';
import 'package:mchs_mobile_app/services/lecture_service.dart';
import 'package:mchs_mobile_app/services/storage_service.dart';
import 'package:mchs_mobile_app/models/lecture_model.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';

class CreateLectureScreen extends ConsumerStatefulWidget {
  const CreateLectureScreen({super.key});

  @override
  ConsumerState<CreateLectureScreen> createState() =>
      _CreateLectureScreenState();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(lectureServiceProvider);
      final response = await service.create(
        CreateLectureRequest(
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
        ),
      );

      if (response.success) {
        refreshAllLectureProviders(ref);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Лекция успешно создана');
          context.pop(true);
        }
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            response.message ?? 'Ошибка создания лекции',
          );
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty) {
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
        final canPop = await _onWillPop();
        if (!context.mounted) return;
        if (canPop) context.pop();
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
                CustomTextField(
                  controller: _titleController,
                  label: 'Название лекции *',
                  hint: 'Введите название',
                  prefixIcon: Icons.title,
                  validator: (v) => Validators.title(v, 'Название лекции'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Содержание лекции',
                    hintText: 'Введите текст лекции...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.description(v, maxLength: 50000),
                ),
                const SectionHeader(title: 'Медиа (необязательно)'),
                StorageFileField(
                  controller: _videoPathController,
                  type: StorageFileType.video,
                  label: 'Видео из хранилища',
                  icon: Icons.video_library_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                StorageFileField(
                  controller: _documentPathController,
                  type: StorageFileType.document,
                  label: 'Документ (PDF) из хранилища',
                  icon: Icons.picture_as_pdf_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  text: 'Создать лекцию',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _createLecture,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomButton(
                  text: 'Отмена',
                  isOutlined: true,
                  onPressed: () async {
                    final canPop = await _onWillPop();
                    if (!context.mounted) return;
                    if (canPop) context.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
