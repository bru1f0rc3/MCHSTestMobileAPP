import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';
import 'package:mchs_mobile_app/features/admin/data/services/reports_service.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/data/models/testing_model.dart';

/// My Statistics Provider
final myStatisticsProvider = FutureProvider.autoDispose<UserStatisticsDto?>((ref) async {
  try {
    final service = ref.watch(reportsServiceProvider);
    final response = await service.getMyStatistics();
    return response.data;
  } catch (e) {
    return null;
  }
});

/// My Test History Provider
final myTestHistoryProvider = FutureProvider.autoDispose<List<TestResultModel>>((ref) async {
  final service = ref.watch(testServiceProvider);
  return service.getTestHistory(pageSize: 10);
});

class UserStatisticsScreen extends ConsumerWidget {
  const UserStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myStatisticsProvider);
    final historyAsync = ref.watch(myTestHistoryProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Моя статистика'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myStatisticsProvider);
          ref.invalidate(myTestHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              statsAsync.when(
                data: (stats) {
                  if (stats == null) {
                    return _buildNoStatsCard(context);
                  }
                  return Column(
                    children: [
                      // Overview Card
                      _buildOverviewCard(context, stats),
                      const SizedBox(height: 16),
                      // Progress Card
                      _buildProgressCard(context, stats),
                      const SizedBox(height: 16),
                      // Performance Card
                      _buildPerformanceCard(context, stats),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildNoStatsCard(context),
              ),
              
              const SizedBox(height: 24),
              
              // Recent Tests
              Text(
                'Последние тесты',
                style: AppTypography.heading4.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return CustomCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: context.textTertiaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Вы еще не проходили тесты',
                            style: AppTypography.body2.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: history.map((result) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTestResultCard(context, result),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => CustomCard(
                  child: Text(
                    'Не удалось загрузить историю',
                    style: AppTypography.body2.copyWith(
                      color: context.errorColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoStatsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет статистики',
            style: AppTypography.heading4.copyWith(
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Пройдите тесты, чтобы увидеть статистику',
            style: AppTypography.body2.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, UserStatisticsDto stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: context.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Общая статистика',
                style: AppTypography.heading4.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Всего тестов',
                  value: '${stats.totalTestsTaken}',
                  icon: Icons.quiz,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Завершено',
                  value: '${stats.testsCompleted}',
                  icon: Icons.check_circle,
                  color: context.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Сдано',
                  value: '${stats.testsPassed}',
                  icon: Icons.thumb_up,
                  color: context.successColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Не сдано',
                  value: '${stats.testsFailed}',
                  icon: Icons.thumb_down,
                  color: context.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, UserStatisticsDto stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Средний балл',
            style: AppTypography.body2.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${stats.averageScore.toStringAsFixed(1)}%',
                style: AppTypography.heading2.copyWith(
                  color: _getScoreColor(context, stats.averageScore),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(context, stats.averageScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getScoreLabel(stats.averageScore),
                  style: AppTypography.caption.copyWith(
                    color: _getScoreColor(context, stats.averageScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.averageScore / 100,
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation(
                _getScoreColor(context, stats.averageScore),
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, UserStatisticsDto stats) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Процент успешных тестов',
            style: AppTypography.body2.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: stats.passRate / 100,
                      strokeWidth: 12,
                      backgroundColor: context.borderColor,
                      valueColor: AlwaysStoppedAnimation(
                        _getScoreColor(context, stats.passRate),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.passRate.toStringAsFixed(0)}%',
                            style: AppTypography.heading3.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'успех',
                            style: AppTypography.caption.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(BuildContext context, TestResultModel result) {
    final isPassed = result.isPassed;
    
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isPassed ? context.successColor : context.errorColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              isPassed ? Icons.check_circle : Icons.cancel,
              color: isPassed ? context.successColor : context.errorColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.testTitle ?? 'Тест #${result.testId}',
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${result.scorePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(
                        color: isPassed ? context.successColor : context.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.finishedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(result.finishedAt!),
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(BuildContext context, double score) {
    if (score >= 80) return context.successColor;
    if (score >= 60) return context.warningColor;
    return context.errorColor;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Отлично';
    if (score >= 80) return 'Хорошо';
    if (score >= 70) return 'Удовлетворительно';
    if (score >= 60) return 'Нужно подтянуть';
    return 'Требует внимания';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.heading4.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
