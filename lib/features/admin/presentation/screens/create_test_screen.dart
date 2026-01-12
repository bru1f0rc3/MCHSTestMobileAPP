import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/core/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';

class CreateTestScreen extends ConsumerStatefulWidget {
  const CreateTestScreen({super.key});

  @override
  ConsumerState<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends ConsumerState<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedLectureId;
  bool _isLoading = false;

  final List<QuestionData> _questions = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionData(
        questionText: '',
        answers: [
          AnswerData(text: '', isCorrect: true),
          AnswerData(text: '', isCorrect: false),
        ],
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  String? _validateQuestions() {
    if (_questions.isEmpty) return 'Добавьте хотя бы один вопрос';
    
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) return 'Введите текст вопроса ${i + 1}';
      if (q.answers.length < 2) return 'В вопросе ${i + 1} должно быть минимум 2 ответа';
      if (q.answers.any((a) => a.text.trim().isEmpty)) return 'Заполните все ответы в вопросе ${i + 1}';
      if (!q.answers.any((a) => a.isCorrect)) return 'Выберите правильный ответ в вопросе ${i + 1}';
    }
    return null;
  }

  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) return;
    
    final questionsError = _validateQuestions();
    if (questionsError != null) {
      ErrorHandler.showErrorSnackBar(context, questionsError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(testServiceProvider);
      final response = await service.create(CreateTestRequest(
        lectureId: _selectedLectureId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        questions: _questions.asMap().entries.map((entry) {
          final qIndex = entry.key;
          final q = entry.value;
          return CreateQuestionRequest(
            questionText: q.questionText.trim(),
            position: qIndex + 1,
            answers: q.answers.asMap().entries.map((aEntry) {
              final aIndex = aEntry.key;
              final a = aEntry.value;
              return CreateAnswerRequest(answerText: a.text.trim(), isCorrect: a.isCorrect, position: aIndex + 1);
            }).toList(),
          );
        }).toList(),
      ));

      if (response.success) {
        refreshAllTestProviders(ref);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Тест успешно создан');
          context.pop(true);
        }
      } else {
        if (mounted) ErrorHandler.showErrorSnackBar(context, response.message ?? 'Ошибка создания теста');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty || _questions.isNotEmpty) {
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
    final lecturesAsync = ref.watch(lecturesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) context.pop();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Создать тест')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
              CustomCard(
                color: AppColors.accent.withOpacity(0.1),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.quiz, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Новый тест', style: AppTypography.body1.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Создайте тест с вопросами', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              lecturesAsync.when(
                data: (lectures) {
                  return DropdownButtonFormField<int>(
                    value: _selectedLectureId,
                    decoration: InputDecoration(
                      labelText: 'Привязать к лекции',
                      prefixIcon: const Icon(Icons.book),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [const DropdownMenuItem(value: null, child: Text('Без лекции')), ...lectures.map((l) => DropdownMenuItem(value: l.id, child: Text(l.title)))],
                    onChanged: (value) => setState(() => _selectedLectureId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Ошибка загрузки лекций'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _titleController,
                label: 'Название теста *',
                hint: 'Введите название',
                prefixIcon: Icons.title,
                validator: (v) => Validators.title(v, 'Название теста'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Введите описание теста',
                prefixIcon: Icons.description,
                maxLines: 2,
                validator: (v) => Validators.description(v, maxLength: 1000),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Вопросы (${_questions.length})', style: AppTypography.heading4.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _addQuestion, icon: const Icon(Icons.add), label: const Text('Добавить')),
                ],
              ),
              const SizedBox(height: 12),
              ..._questions.asMap().entries.map((entry) => _QuestionCard(index: entry.key, question: entry.value, onRemove: () => _removeQuestion(entry.key), onChanged: () => setState(() {}))),
              if (_questions.isEmpty)
                CustomCard(
                  child: Column(
                    children: [
                      Icon(Icons.help_outline, size: 48, color: context.textTertiaryColor),
                      const SizedBox(height: 12),
                      Text('Добавьте вопросы', style: AppTypography.body2.copyWith(color: context.textSecondaryColor)),
                      const SizedBox(height: 16),
                      CustomButton(text: 'Добавить вопрос', icon: Icons.add, onPressed: _addQuestion),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              CustomButton(text: 'Создать тест', icon: Icons.check, isLoading: _isLoading, onPressed: _isLoading ? null : _createTest),
              const SizedBox(height: 16),
              CustomButton(text: 'Отмена', isOutlined: true, onPressed: () async { if (await _onWillPop()) context.pop(); }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionData {
  String questionText;
  List<AnswerData> answers;

  QuestionData({
    required this.questionText,
    required this.answers,
  });
}

class AnswerData {
  String text;
  bool isCorrect;

  AnswerData({
    required this.text,
    required this.isCorrect,
  });
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionData question;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вопрос ${index + 1}',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Текст вопроса',
                hintText: 'Введите вопрос',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                question.questionText = value;
                onChanged();
              },
              controller: TextEditingController(text: question.questionText),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ответы',
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    question.answers.add(AnswerData(text: '', isCorrect: false));
                    onChanged();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...question.answers.asMap().entries.map((entry) {
              final answerIndex = entry.key;
              final answer = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: answerIndex,
                      groupValue: question.answers.indexWhere((a) => a.isCorrect),
                      onChanged: (value) {
                        for (var a in question.answers) {
                          a.isCorrect = false;
                        }
                        answer.isCorrect = true;
                        onChanged();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ответ ${answerIndex + 1}',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: answer.isCorrect
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          answer.text = value;
                          onChanged();
                        },
                        controller: TextEditingController(text: answer.text),
                      ),
                    ),
                    if (question.answers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          question.answers.removeAt(answerIndex);
                          if (!question.answers.any((a) => a.isCorrect) &&
                              question.answers.isNotEmpty) {
                            question.answers.first.isCorrect = true;
                          }
                          onChanged();
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
