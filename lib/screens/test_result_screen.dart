import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/models/testing_model.dart';
import 'package:mchs_mobile_app/services/test_service.dart';
import 'package:mchs_mobile_app/providers/test_provider.dart';

final testResultProvider =
    FutureProvider.family<TestResultDetailModel?, int>((ref, id) async {
  final testService = ref.watch(testServiceProvider);
  return await testService.getTestResult(id);
});

class TestResultScreen extends ConsumerWidget {
  final int testResultId;

  const TestResultScreen({super.key, required this.testResultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(testResultProvider(testResultId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Результаты теста'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: resultAsync.when(
        data: (result) {
          if (result == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Результаты не найдены',
            );
          }

          final passed = result.scorePercentage >= 70.0;
          final color = passed ? context.successColor : context.errorColor;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _ResultHero(
                passed: passed,
                color: color,
                score: result.scorePercentage,
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Результат',
                      value: '${result.scorePercentage.toStringAsFixed(1)}%',
                    ),
                    _divider(context),
                    _StatRow(
                      label: 'Проходной балл',
                      value: '${result.passingScore}%',
                    ),
                    _divider(context),
                    _StatRow(
                      label: 'Завершён',
                      value: _formatDate(
                        result.finishedAt ?? DateTime.now(),
                      ),
                    ),
                    if (result.elapsed != null) ...[
                      _divider(context),
                      _StatRow(
                        label: 'Время',
                        value: _elapsed(
                          result.elapsed!,
                          result.timeLimitMinutes,
                        ),
                      ),
                    ],
                    if (result.cheatAttempts > 0) ...[
                      _divider(context),
                      _StatRow(
                        label: 'Подозрительных действий',
                        value: '${result.cheatAttempts}',
                        valueColor: context.errorColor,
                      ),
                    ],
                    if (result.autoSubmitted) ...[
                      _divider(context),
                      const _StatRow(
                        label: 'Завершение',
                        value: 'Авто (таймаут)',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                text: 'На главную',
                icon: Icons.home_outlined,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomButton(
                text: 'Пройти повторно',
                icon: Icons.replay_rounded,
                isOutlined: true,
                onPressed: () {
                  refreshAllTestProviders(ref);
                  context.push('/test-detail/${result.testId}');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomButton(
                text: 'Все тесты',
                icon: Icons.list_alt_outlined,
                isOutlined: true,
                onPressed: () => context.go('/tests'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(message: error.toString()),
      ),
    );
  }

  static Widget _divider(BuildContext context) =>
      Divider(height: 1, color: context.dividerColor);

  static String _formatDate(DateTime d) =>
      '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  static String _elapsed(Duration elapsed, int? limitMinutes) {
    final e = _fmt(elapsed);
    if (limitMinutes == null || limitMinutes <= 0) return e;
    return '$e из ${_fmt(Duration(minutes: limitMinutes))}';
  }

  static String _fmt(Duration d) {
    final c = d.isNegative ? Duration.zero : d;
    String two(int n) => n.toString().padLeft(2, '0');
    final h = c.inHours;
    final m = c.inMinutes.remainder(60);
    final s = c.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}

class _ResultHero extends StatelessWidget {
  final bool passed;
  final Color color;
  final double score;

  const _ResultHero({
    required this.passed,
    required this.color,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed
                  ? Icons.check_circle_outline_rounded
                  : Icons.close_rounded,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            passed ? 'Тест пройден' : 'Тест не пройден',
            style: AppTypography.heading3.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: AppTypography.heading1.copyWith(
              color: context.textPrimaryColor,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.body1.copyWith(
              color: valueColor ?? context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
