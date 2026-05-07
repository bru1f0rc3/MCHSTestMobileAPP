import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/services/test_service.dart';
import 'package:mchs_mobile_app/models/test_model.dart';
import 'package:mchs_mobile_app/providers/test_provider.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';

class EditTestScreen extends ConsumerStatefulWidget {
  final int testId;

  const EditTestScreen({super.key, required this.testId});

  @override
  ConsumerState<EditTestScreen> createState() => _EditTestScreenState();
}

class _EditTestScreenState extends ConsumerState<EditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  int? _selectedLectureId;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<EditableQuestion> _questions = [];
  final List<int> _deletedQuestionIds = [];
  final List<int> _deletedAnswerIds = [];

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadTestData() async {
    try {
      final testService = ref.read(testServiceProvider);
      final test = await testService.getTestDetail(widget.testId);

      if (test == null) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Тест не найден');
          context.pop();
        }
        return;
      }

      setState(() {
        _titleController.text = test.title;
        _descriptionController.text = test.description ?? '';
        _selectedLectureId = test.lectureId;
        _timeLimitController.text = test.timeLimitMinutes?.toString() ?? '';
        _passingScoreController.text = test.passingScore.toString();

        _questions.clear();
        for (final q in test.questions) {
          _questions.add(
            EditableQuestion(
              id: q.id,
              questionText: q.questionText,
              answers: q.answers
                  .map(
                    (a) => EditableAnswer(
                      id: a.id,
                      text: a.answerText,
                      isCorrect: a.isCorrect,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        context.pop();
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        EditableQuestion(
          questionText: '',
          answers: [
            EditableAnswer(text: '', isCorrect: true),
            EditableAnswer(text: '', isCorrect: false),
          ],
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    final question = _questions[index];
    if (question.id != null) {
      _deletedQuestionIds.add(question.id!);
    }
    setState(() => _questions.removeAt(index));
  }

  void _addAnswer(int questionIndex) {
    setState(() {
      _questions[questionIndex].answers.add(
        EditableAnswer(text: '', isCorrect: false),
      );
    });
  }

  void _removeAnswer(int questionIndex, int answerIndex) {
    final answer = _questions[questionIndex].answers[answerIndex];
    if (answer.id != null) {
      _deletedAnswerIds.add(answer.id!);
    }
    setState(() {
      _questions[questionIndex].answers.removeAt(answerIndex);
      final answers = _questions[questionIndex].answers;
      if (answers.isNotEmpty && !answers.any((a) => a.isCorrect)) {
        answers.first.isCorrect = true;
      }
    });
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

  Future<void> _saveTest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final questionsError = _validateQuestions();
    if (questionsError != null) {
      ErrorHandler.showErrorSnackBar(context, questionsError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(testServiceProvider);

      final timeLimitRaw = _timeLimitController.text.trim();
      final parsedLimit = int.tryParse(timeLimitRaw);
      final clearLimit = timeLimitRaw.isEmpty;
      final parsedPassing = int.tryParse(_passingScoreController.text.trim());

      final updateResult = await service.update(
        widget.testId,
        UpdateTestRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          lectureId: _selectedLectureId,
          timeLimitMinutes: (parsedLimit != null && parsedLimit > 0)
              ? parsedLimit
              : null,
          clearTimeLimit: clearLimit,
          passingScore: parsedPassing,
        ),
      );

      if (!updateResult.success) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            updateResult.message ?? 'Ошибка обновления теста',
          );
        }
        return;
      }
      for (final questionId in _deletedQuestionIds) {
        await service.deleteQuestion(questionId);
      }
      for (final answerId in _deletedAnswerIds) {
        try {
          await service.deleteAnswer(answerId);
        } catch (_) {}
      }
      for (var qIndex = 0; qIndex < _questions.length; qIndex++) {
        final q = _questions[qIndex];

        if (q.id != null) {
          await service.updateQuestion(
            q.id!,
            UpdateQuestionRequest(
              questionText: q.questionText.trim(),
              position: qIndex + 1,
            ),
          );
          for (var aIndex = 0; aIndex < q.answers.length; aIndex++) {
            final a = q.answers[aIndex];
            if (a.id != null) {
              await service.updateAnswer(
                a.id!,
                UpdateAnswerRequest(
                  answerText: a.text.trim(),
                  isCorrect: a.isCorrect,
                  position: aIndex + 1,
                ),
              );
            } else {
              await service.addAnswer(
                q.id!,
                CreateAnswerRequest(
                  answerText: a.text.trim(),
                  isCorrect: a.isCorrect,
                  position: aIndex + 1,
                ),
              );
            }
          }
        } else {
          await service.addQuestion(
            widget.testId,
            CreateQuestionRequest(
              questionText: q.questionText.trim(),
              position: qIndex + 1,
              answers: q.answers.asMap().entries.map((entry) {
                return CreateAnswerRequest(
                  answerText: entry.value.text.trim(),
                  isCorrect: entry.value.isCorrect,
                  position: entry.key + 1,
                );
              }).toList(),
            ),
          );
        }
      }

      refreshAllTestProviders(ref);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Тест успешно обновлен');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    return await ErrorHandler.showConfirmDialog(
      context,
      title: 'Отменить редактирование?',
      message: 'Вы уверены? Все несохраненные изменения будут потеряны.',
      confirmText: 'Отменить',
      isDangerous: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(title: const Text('Редактировать тест')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        appBar: AppBar(title: const Text('Редактировать тест')),
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
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _EditableQuestionCard(
                  index: index,
                  question: question,
                  onRemove: () => _removeQuestion(index),
                  onAddAnswer: () => _addAnswer(index),
                  onRemoveAnswer: (answerIndex) =>
                      _removeAnswer(index, answerIndex),
                  onChanged: () => setState(() {}),
                );
              }),
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
                text: 'Сохранить',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveTest,
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

class EditableQuestion {
  int? id;
  String questionText;
  List<EditableAnswer> answers;

  EditableQuestion({
    this.id,
    required this.questionText,
    required this.answers,
  });
}

class EditableAnswer {
  int? id;
  String text;
  bool isCorrect;

  EditableAnswer({this.id, required this.text, required this.isCorrect});
}

class _EditableQuestionCard extends StatelessWidget {
  final int index;
  final EditableQuestion question;
  final VoidCallback onRemove;
  final VoidCallback onAddAnswer;
  final void Function(int) onRemoveAnswer;
  final VoidCallback onChanged;

  const _EditableQuestionCard({
    required this.index,
    required this.question,
    required this.onRemove,
    required this.onAddAnswer,
    required this.onRemoveAnswer,
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
                  onPressed: onAddAnswer,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                'Отметьте все правильные варианты (можно несколько)',
                style: AppTypography.caption.copyWith(
                  color: context.textTertiaryColor,
                ),
              ),
            ),
            ...question.answers.asMap().entries.map((entry) {
              final answerIndex = entry.key;
              final answer = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Checkbox(
                      value: answer.isCorrect,
                      onChanged: (value) {
                        answer.isCorrect = value ?? false;
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
                        onPressed: () => onRemoveAnswer(answerIndex),
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
