import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';import 'package:mchs_mobile_app/core/utils/error_handler.dart';import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final int testId;

  const TestTakingScreen({super.key, required this.testId});

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen> {
  TestDetailModel? _test;
  int? _testResultId;
  int _currentQuestionIndex = 0;
  Map<int, Set<int>> _selectedAnswers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  Future<void> _startTest() async {
    try {
      final testService = ref.read(testServiceProvider);
      final test = await testService.getTestDetail(widget.testId);
      
      if (test == null) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Тест не найден');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
        return;
      }

      final result = await testService.startTest(widget.testId);
      
      setState(() {
        _test = test;
        _testResultId = result.testResultId;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      }
    }
  }

  void _selectAnswer(int questionId, int answerId, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        if (_selectedAnswers[questionId] == null) {
          _selectedAnswers[questionId] = {};
        }
        if (_selectedAnswers[questionId]!.contains(answerId)) {
          _selectedAnswers[questionId]!.remove(answerId);
        } else {
          _selectedAnswers[questionId]!.add(answerId);
        }
      } else {
        _selectedAnswers[questionId] = {answerId};
      }
    });
  }

  Future<void> _submitTest() async {
    if (_testResultId == null || _test == null) return;

    // Проверяем, что все вопросы отвечены
    for (var question in _test!.questions) {
      if (!_selectedAnswers.containsKey(question.id) || _selectedAnswers[question.id]!.isEmpty) {
        ErrorHandler.showWarningSnackBar(context, 'Пожалуйста, ответьте на все вопросы перед отправкой теста.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final testService = ref.read(testServiceProvider);
      
      final answers = _selectedAnswers.entries
          .map((entry) => {'questionId': entry.key, 'answerIds': entry.value.toList()})
          .toList();

      await testService.submitAnswers(_testResultId!, answers);
      final result = await testService.finishTest(_testResultId!);

      // Обновляем все провайдеры тестов
      refreshAllTestProviders(ref);

      if (mounted) context.go('/test-result/${result.testResultId}');
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _onWillPop() async {
    return await ErrorHandler.showConfirmDialog(
      context,
      title: 'Выйти из теста?',
      message: 'Ваши ответы не будут сохранены.',
      confirmText: 'Выйти',
      isDangerous: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_test == null) {
      return const Scaffold(
        body: Center(child: Text('Тест не найден')),
      );
    }

    final question = _test!.questions[_currentQuestionIndex];
    final isMultipleChoice = question.answers.where((a) => a.isCorrect).length > 1;
    final progress = (_currentQuestionIndex + 1) / _test!.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) context.pop();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text('Вопрос ${_currentQuestionIndex + 1} из ${_test!.questions.length}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Вопрос ${_currentQuestionIndex + 1}',
                            style: AppTypography.caption.copyWith(
                              color: context.textTertiaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.questionText,
                            style: AppTypography.heading4.copyWith(
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isMultipleChoice)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: context.infoColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Можно выбрать несколько вариантов',
                                    style: AppTypography.caption.copyWith(
                                      color: context.infoColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Answers
                    ...question.answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final isSelected = _selectedAnswers[question.id]?.contains(answer.id) ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnswerOption(
                          index: index,
                          text: answer.answerText,
                          isSelected: isSelected,
                          onTap: () => _selectAnswer(question.id, answer.id, isMultipleChoice),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Назад',
                        isOutlined: true,
                        onPressed: () {
                          setState(() => _currentQuestionIndex--);
                        },
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentQuestionIndex == _test!.questions.length - 1
                          ? 'Завершить тест'
                          : 'Далее',
                      isLoading: _isSubmitting,
                      onPressed: () {
                        if (_currentQuestionIndex == _test!.questions.length - 1) {
                          _submitTest();
                        } else {
                          setState(() => _currentQuestionIndex++);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  static const _optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      color: isSelected ? context.primaryColor.withOpacity(0.05) : context.surfaceColor,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? context.primaryColor : context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? context.primaryColor : context.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                index < _optionLabels.length ? _optionLabels[index] : '${index + 1}',
                style: AppTypography.body1.copyWith(
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body1.copyWith(
                color: context.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: context.primaryColor,
              size: 24,
            ),
        ],
      ),
    );
  }
}
