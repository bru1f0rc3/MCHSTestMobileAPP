import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

class TestHistoryScreen extends ConsumerWidget {
  const TestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(testHistoryProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('История тестов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(testHistoryProvider),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(testHistoryProvider),
        child: historyAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: context.textTertiaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'История пуста',
                    style: AppTypography.heading4.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Вы еще не проходили тесты',
                    style: AppTypography.body2.copyWith(
                      color: context.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppSpacing.paddingMd,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final passed = result.scorePercentage >= 70.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  onTap: () => context.push('/test-result/${result.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: passed
                                  ? context.successColor.withOpacity(0.1)
                                  : context.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              passed ? Icons.check_circle : Icons.cancel,
                              color: passed ? context.successColor : context.errorColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.testTitle ?? 'Тест #${result.testId}',
                                  style: AppTypography.heading4.copyWith(
                                    color: context.textPrimaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(result.finishedAt ?? DateTime.now()),
                                  style: AppTypography.caption.copyWith(
                                    color: context.textTertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${result.scorePercentage.toStringAsFixed(0)}%',
                                style: AppTypography.heading3.copyWith(
                                  color: passed ? context.successColor : context.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                passed ? 'Пройден' : 'Не пройден',
                                style: AppTypography.caption.copyWith(
                                  color: passed ? context.successColor : context.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.grade,
                            label: passed ? 'Успешно' : 'Не сдан',
                            color: passed ? context.successColor : context.errorColor,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context.push('/test-detail/${result.testId}'),
                            icon: const Icon(Icons.replay, size: 18),
                            label: const Text('Перепройти'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTypography.body2.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
