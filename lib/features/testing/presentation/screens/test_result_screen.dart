import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/data/models/testing_model.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

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
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: resultAsync.when(
        data: (result) {
          if (result == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: context.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Результаты не найдены',
                    style: AppTypography.heading4.copyWith(color: context.errorColor),
                  ),
                ],
              ),
            );
          }

          final passed = result.scorePercentage >= 70.0;

          return SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result Card
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    gradient: passed
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.success, Color(0xFF1E7D6B)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.error, Color(0xFFC93545)],
                          ),
                    borderRadius: AppRadius.borderRadiusLg,
                    boxShadow: AppShadows.md,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        passed ? Icons.check_circle : Icons.cancel,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        passed ? 'Тест пройден!' : 'Тест не пройден',
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        passed
                            ? 'Поздравляем! Вы успешно прошли тест'
                            : 'К сожалению, вы не набрали проходной балл',
                        style: AppTypography.body2.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${result.scorePercentage.toStringAsFixed(1)}%',
                            style: AppTypography.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Statistics
                Text(
                  'Статистика',
                  style: AppTypography.heading4.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.percent,
                        label: 'Процент правильных',
                        value: '${result.scorePercentage.toStringAsFixed(1)}%',
                        color: AppColors.info,
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        icon: Icons.timer,
                        label: 'Дата прохождения',
                        value: _formatDate(result.finishedAt ?? DateTime.now()),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                CustomButton(
                  text: 'На главную',
                  icon: Icons.home,
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Пройти тест повторно',
                  icon: Icons.replay,
                  isOutlined: true,
                  onPressed: () {
                    refreshAllTestProviders(ref);
                    context.push('/test-detail/${result.testId}');
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Посмотреть все тесты',
                  icon: Icons.quiz,
                  isOutlined: true,
                  onPressed: () => context.go('/tests'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: context.errorColor),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: AppTypography.heading4.copyWith(color: context.errorColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 16),
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
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
