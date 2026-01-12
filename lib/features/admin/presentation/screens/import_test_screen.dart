import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/core/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/features/admin/data/services/pdf_import_service.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

/// Screen for importing tests from PDF
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
      if (mounted) ErrorHandler.showErrorSnackBar(context, 'Ошибка выбора файла: $e');
    }
  }

  Future<void> _importTest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPdfBytes == null) {
      ErrorHandler.showWarningSnackBar(context, 'Выберите PDF файл для импорта');
      return;
    }
    
    if (_selectedLectureId == null) {
      ErrorHandler.showWarningSnackBar(context, 'Выберите лекцию для привязки теста');
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
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        onProgress: (sent, total) => setState(() => _uploadProgress = sent / total),
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
                  Icon(result.isComplete ? Icons.check_circle : Icons.warning, color: result.isComplete ? AppColors.success : AppColors.warning),
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
                    const Text('Ошибки:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                    const SizedBox(height: 8),
                    ...result.errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $error', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    )),
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
          ErrorHandler.showErrorSnackBar(context, response.message ?? 'Ошибка импорта');
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
      appBar: AppBar(
        title: const Text('Импорт теста из PDF'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              CustomCard(
                color: AppColors.info.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Формат PDF: Вопрос, затем варианты ответов. '
                        'Правильный ответ отметьте [true]',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Field
              CustomTextField(
                controller: _titleController,
                label: 'Название теста',
                hint: 'Введите название теста',
                validator: (v) => Validators.title(v, 'Название теста'),
              ),
              const SizedBox(height: 16),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание (необязательно)',
                hint: 'Введите описание теста',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Lecture Selector
              Text(
                'Выберите лекцию',
                style: AppTypography.body1.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              lecturesAsync.when(
                data: (lectures) {
                  if (lectures.isEmpty) {
                    return CustomCard(
                      child: Text(
                        'Нет доступных лекций. Создайте лекцию сначала.',
                        style: AppTypography.body2.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    );
                  }

                  return CustomCard(
                    child: DropdownButtonFormField<int>(
                      value: _selectedLectureId,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      hint: const Text('Выберите лекцию'),
                      items: lectures.map((lecture) {
                        return DropdownMenuItem<int>(
                          value: lecture.id,
                          child: Text(lecture.title),
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
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => CustomCard(
                  child: Text(
                    'Ошибка загрузки лекций: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // PDF File Picker
              Text(
                'Файл PDF с тестом',
                style: AppTypography.body1.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomCard(
                onTap: _isUploading ? null : _pickPdfFile,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedPdfBytes != null
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedPdfBytes != null
                            ? Icons.check_circle
                            : Icons.picture_as_pdf,
                        color: _selectedPdfBytes != null
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Выберите PDF файл',
                        style: AppTypography.body1.copyWith(
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: context.textTertiaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload Progress
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Загрузка... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              // Import Button
              CustomButton(
                text: 'Импортировать тест',
                icon: Icons.upload_file,
                onPressed: _isUploading ? null : _importTest,
                isLoading: _isUploading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
