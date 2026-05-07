import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/services/pdf_import_service.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/providers/test_provider.dart';

class ImportTestFromPdfScreen extends ConsumerStatefulWidget {
  const ImportTestFromPdfScreen({super.key});

  @override
  ConsumerState<ImportTestFromPdfScreen> createState() =>
      _ImportTestFromPdfScreenState();
}

class _ImportTestFromPdfScreenState
    extends ConsumerState<ImportTestFromPdfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _selectedPdfBytes;
  String? _selectedFileName;
  int? _selectedLectureId;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedPdfBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Ошибка выбора файла: $e');
      }
    }
  }

  Future<void> _importTest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedPdfBytes == null) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Выберите PDF файл для импорта',
      );
      return;
    }

    if (_selectedLectureId == null) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Выберите лекцию для привязки теста',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final pdfImportService = ref.read(pdfImportServiceProvider);

      final response = await pdfImportService.importTestFromPdfBytes(
        pdfBytes: _selectedPdfBytes!,
        fileName: _selectedFileName ?? 'test.pdf',
        lectureId: _selectedLectureId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        onProgress: (sent, total) =>
            setState(() => _uploadProgress = sent / total),
      );

      setState(() => _isUploading = false);

      if (mounted) {
        if (response.success && response.data != null) {
          final result = response.data!;

          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    result.isComplete ? Icons.check_circle : Icons.warning,
                    color: result.isComplete
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  const Text('Импорт завершен'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тест: ${result.title}'),
                  if (result.hasErrors) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ошибки:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $error',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (result.isComplete) {
                      refreshAllTestProviders(ref);
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ErrorHandler.showErrorSnackBar(
            context,
            response.message ?? 'Ошибка импорта',
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecturesAsync = ref.watch(lecturesProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Импорт теста из PDF')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Формат PDF: вопрос и варианты ответов. Правильный — [true]',
                        style: AppTypography.caption.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                controller: _titleController,
                label: 'Название теста',
                hint: 'Введите название теста',
                prefixIcon: Icons.title,
                validator: (v) => Validators.title(v, 'Название теста'),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание (необязательно)',
                hint: 'Введите описание теста',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              lecturesAsync.when(
                data: (lectures) {
                  if (lectures.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.surfaceVariantColor,
                        borderRadius: AppRadius.borderRadiusMd,
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        'Нет доступных лекций. Создайте лекцию сначала.',
                        style: AppTypography.body2.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedLectureId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Привязать к лекции',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: lectures.map((lecture) {
                      return DropdownMenuItem<int>(
                        value: lecture.id,
                        child: Text(
                          lecture.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLectureId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите лекцию';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text(
                  'Ошибка загрузки лекций: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomCard(
                onTap: _isUploading ? null : _pickPdfFile,
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
                        color: (_selectedPdfBytes != null
                                ? AppColors.success
                                : context.primaryColor)
                            .withValues(alpha: 0.10),
                        borderRadius: AppRadius.borderRadiusSm,
                      ),
                      child: Icon(
                        _selectedPdfBytes != null
                            ? Icons.check_circle_outline
                            : Icons.picture_as_pdf_outlined,
                        size: 20,
                        color: _selectedPdfBytes != null
                            ? AppColors.success
                            : context.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName ?? 'Выберите PDF файл',
                            style: AppTypography.body1.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _selectedPdfBytes != null
                                ? 'Готов к загрузке'
                                : 'Нажмите, чтобы выбрать',
                            style: AppTypography.caption.copyWith(
                              color: context.textTertiaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textTertiaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Загрузка… ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              CustomButton(
                text: 'Импортировать',
                icon: Icons.upload_file_outlined,
                onPressed: _isUploading ? null : _importTest,
                isLoading: _isUploading,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
