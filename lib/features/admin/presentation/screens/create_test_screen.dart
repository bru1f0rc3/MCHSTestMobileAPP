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
  final _timeLimitController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  int? _selectedLectureId;
  bool _isLoading = false;

  final List<QuestionData> _questions = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        QuestionData(
          questionText: '',
          answers: [
            AnswerData(text: '', isCorrect: true),
            AnswerData(text: '', isCorrect: false),
          ],
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  String? _validateQuestions() {
    if (_questions.isEmpty) return 'Добавьте хотя бы один вопрос';

    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        return 'Введите текст вопроса ${i + 1}';
      }
      if (q.answers.length < 2) {
        return 'В вопросе ${i + 1} должно быть минимум 2 ответа';
      }
      if (q.answers.any((a) => a.text.trim().isEmpty)) {
        return 'Заполните все ответы в вопросе ${i + 1}';
      }
      if (!q.answers.any((a) => a.isCorrect)) {
        return 'Выберите правильный ответ в вопросе ${i + 1}';
      }
    }
    return null;
  }

  Future<void> _createTest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final questionsError = _validateQuestions();
    if (questionsError != null) {
      ErrorHandler.showErrorSnackBar(context, questionsError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(testServiceProvider);
      final timeLimitMinutes = int.tryParse(_timeLimitController.text.trim());
      final passingScore = int.tryParse(_passingScoreController.text.trim());

      final response = await service.create(
        CreateTestRequest(
          lectureId: _selectedLectureId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          timeLimitMinutes: (timeLimitMinutes != null && timeLimitMinutes > 0)
              ? timeLimitMinutes
              : null,
          passingScore: passingScore,
          questions: _questions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final q = entry.value;
            return CreateQuestionRequest(
              questionText: q.questionText.trim(),
              position: qIndex + 1,
              answers: q.answers.asMap().entries.map((aEntry) {
                final aIndex = aEntry.key;
                final a = aEntry.value;
                return CreateAnswerRequest(
                  answerText: a.text.trim(),
                  isCorrect: a.isCorrect,
                  position: aIndex + 1,
                );
              }).toList(),
            );
          }).toList(),
        ),
      );

      if (response.success) {
        refreshAllTestProviders(ref);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Тест успешно создан');
          context.pop(true);
        }
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            response.message ?? 'Ошибка создания теста',
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
        final canPop = await _onWillPop();
        if (!context.mounted) return;
        if (canPop) context.pop();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Создать тест')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
              lecturesAsync.when(
                data: (lectures) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedLectureId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Привязать к лекции',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Без лекции'),
                      ),
                      ...lectures.map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedLectureId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Ошибка загрузки лекций'),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _titleController,
                label: 'Название теста *',
                hint: 'Введите название',
                prefixIcon: Icons.title,
                validator: (v) => Validators.title(v, 'Название теста'),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Введите описание теста',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
                validator: (v) => Validators.description(v, maxLength: 1000),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _timeLimitController,
                      label: 'Время (мин)',
                      hint: 'Без лимита',
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Введите положительное число';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _passingScoreController,
                      label: 'Проходной балл %',
                      hint: '70',
                      prefixIcon: Icons.emoji_events_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 100) return '0–100';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SectionHeader(
                title: 'Вопросы (${_questions.length})',
                action: 'Добавить',
                onAction: _addQuestion,
              ),
              ..._questions.asMap().entries.map(
                (entry) => _QuestionCard(
                  index: entry.key,
                  question: entry.value,
                  onRemove: () => _removeQuestion(entry.key),
                  onChanged: () => setState(() {}),
                ),
              ),
              if (_questions.isEmpty)
                EmptyState(
                  icon: Icons.help_outline_rounded,
                  title: 'Пока нет вопросов',
                  message: 'Добавьте первый вопрос теста',
                  action: ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Добавить вопрос'),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                text: 'Создать тест',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _createTest,
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
              const SizedBox(height: AppSpacing.xxl),
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

  QuestionData({required this.questionText, required this.answers});
}

class AnswerData {
  String text;
  bool isCorrect;

  AnswerData({required this.text, required this.isCorrect});
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.10),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.caption.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Вопрос ${index + 1}',
                    style: AppTypography.body1.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Удалить вопрос',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: question.questionText,
              decoration: const InputDecoration(
                labelText: 'Текст вопроса',
                hintText: 'Введите вопрос',
              ),
              maxLines: null,
              onChanged: (value) {
                question.questionText = value;
                onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ответы',
                  style: AppTypography.body2.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    question.answers.add(
                      AnswerData(text: '', isCorrect: false),
                    );
                    onChanged();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ...question.answers.asMap().entries.map((entry) {
              final answerIndex = entry.key;
              final answer = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Radio<int>(
                      value: answerIndex,
                      groupValue: question.answers.indexWhere(
                        (a) => a.isCorrect,
                      ),
                      onChanged: (value) {
                        for (var a in question.answers) {
                          a.isCorrect = false;
                        }
                        answer.isCorrect = true;
                        onChanged();
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: answer.text,
                        decoration: InputDecoration(
                          hintText: 'Ответ ${answerIndex + 1}',
                          isDense: true,
                          fillColor: answer.isCorrect
                              ? AppColors.success.withValues(alpha: 0.10)
                              : null,
                        ),
                        onChanged: (value) {
                          answer.text = value;
                          onChanged();
                        },
                      ),
                    ),
                    if (question.answers.length > 2)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.textTertiaryColor,
                        ),
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
