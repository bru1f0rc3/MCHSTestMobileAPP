import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/data/models/testing_model.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final int testId;

  const TestTakingScreen({super.key, required this.testId});

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen>
    with WidgetsBindingObserver {
  TestDetailModel? _test;
  StartTestResponse? _session;
  int? _testResultId;
  int _currentQuestionIndex = 0;
  final Map<int, Set<int>> _selectedAnswers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasAutoSubmitted = false;

  Timer? _timer;
  Duration _remaining = Duration.zero;
  int _cheatAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_testResultId == null || _isSubmitting || _hasAutoSubmitted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _reportCheat(
        eventType: state == AppLifecycleState.paused
            ? 'app_background'
            : 'app_inactive',
        details: 'Lifecycle: ${state.toString()}',
      );
    }
  }

  Future<void> _reportCheat({
    required String eventType,
    String? details,
  }) async {
    if (_testResultId == null) return;
    final svc = ref.read(testServiceProvider);
    final ok = await svc.reportCheatAttempt(
      _testResultId!,
      eventType: eventType,
      details: details,
    );
    if (ok && mounted) {
      setState(() => _cheatAttempts++);
    }
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

      if (test.questions.isEmpty) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            'В тесте нет вопросов. Обратитесь к администратору.',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
        return;
      }

      final session = await testService.startTest(widget.testId);

      setState(() {
        _test = test;
        _session = session;
        _testResultId = session.testResultId;
        _isLoading = false;
      });

      _setupTimer();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      }
    }
  }

  void _setupTimer() {
    final deadline = _session?.deadlineAt;
    if (deadline == null) return;

    _updateRemaining(deadline);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(deadline);
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        _autoSubmitOnTimeout();
      }
    });
  }

  void _updateRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  Future<void> _autoSubmitOnTimeout() async {
    if (_hasAutoSubmitted || _testResultId == null) return;
    _hasAutoSubmitted = true;

    try {
      final testService = ref.read(testServiceProvider);
      if (_selectedAnswers.isNotEmpty) {
        final answers = _selectedAnswers.entries
            .map((e) => {'questionId': e.key, 'answerIds': e.value.toList()})
            .toList();
        try {
          await testService.submitAnswers(_testResultId!, answers);
        } catch (_) {}
      }
      final result = await testService.finishTest(_testResultId!);
      refreshAllTestProviders(ref);
      if (mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Время вышло. Тест завершён автоматически.',
        );
        context.go('/test-result/${result.testResultId}');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _selectAnswer(int questionId, int answerId, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        _selectedAnswers[questionId] ??= {};
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
    if (_isSubmitting || _hasAutoSubmitted) return;
    if (_testResultId == null || _test == null) return;

    for (var question in _test!.questions) {
      if (!_selectedAnswers.containsKey(question.id) ||
          _selectedAnswers[question.id]!.isEmpty) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Пожалуйста, ответьте на все вопросы перед отправкой теста.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final testService = ref.read(testServiceProvider);

      final answers = _selectedAnswers.entries
          .map(
            (entry) => {
              'questionId': entry.key,
              'answerIds': entry.value.toList(),
            },
          )
          .toList();

      await testService.submitAnswers(_testResultId!, answers);
      final result = await testService.finishTest(_testResultId!);

      refreshAllTestProviders(ref);

      if (mounted) context.go('/test-result/${result.testResultId}');
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_test == null) {
      return const Scaffold(body: Center(child: Text('Тест не найден')));
    }

    if (_test!.questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('В тесте нет вопросов')));
    }

    final safeIndex = _currentQuestionIndex.clamp(
      0,
      _test!.questions.length - 1,
    );
    final question = _test!.questions[safeIndex];
    final isMultipleChoice =
        question.answers.where((a) => a.isCorrect).length > 1;
    final progress = (safeIndex + 1) / _test!.questions.length;
    final hasTimer = _session?.deadlineAt != null;
    final isTimeCritical = hasTimer && _remaining.inMinutes < 1;

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
        appBar: AppBar(
          title: Text('Вопрос ${safeIndex + 1} из ${_test!.questions.length}'),
          actions: [
            if (hasTimer)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isTimeCritical
                        ? context.errorColor.withValues(alpha: 0.15)
                        : context.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: isTimeCritical
                            ? context.errorColor
                            : context.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_remaining),
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isTimeCritical
                              ? context.errorColor
                              : context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_cheatAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                child: Tooltip(
                  message:
                      'Зафиксировано подозрительных действий: $_cheatAttempts.\nНе сворачивайте приложение.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.errorColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: context.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_cheatAttempts',
                          style: AppTypography.body2.copyWith(
                            color: context.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вопрос ${safeIndex + 1} из ${_test!.questions.length}',
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      question.questionText,
                      style: AppTypography.heading3.copyWith(
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (isMultipleChoice) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.check_box_outlined,
                            size: 14,
                            color: context.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Можно выбрать несколько вариантов',
                            style: AppTypography.caption.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ...question.answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final isSelected =
                          _selectedAnswers[question.id]?.contains(answer.id) ??
                          false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AnswerOption(
                          index: index,
                          text: answer.answerText,
                          isSelected: isSelected,
                          onTap: () => _selectAnswer(
                            question.id,
                            answer.id,
                            isMultipleChoice,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(
                  top: BorderSide(color: context.borderColor),
                ),
              ),
              child: Row(
                children: [
                  if (safeIndex > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Назад',
                        isOutlined: true,
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(
                                  () => _currentQuestionIndex = safeIndex - 1,
                                );
                              },
                      ),
                    ),
                  if (safeIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: safeIndex == _test!.questions.length - 1
                          ? 'Завершить тест'
                          : 'Далее',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (safeIndex == _test!.questions.length - 1) {
                                _submitTest();
                              } else {
                                setState(
                                  () => _currentQuestionIndex = safeIndex + 1,
                                );
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
    final bg = isSelected
        ? context.primaryColor.withValues(alpha: 0.06)
        : context.surfaceColor;
    final borderColor =
        isSelected ? context.primaryColor : context.borderColor;

    return Material(
      color: bg,
      borderRadius: AppRadius.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor
                        : context.surfaceVariantColor,
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    index < _optionLabels.length
                        ? _optionLabels[index]
                        : '${index + 1}',
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.textSecondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.body1.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
