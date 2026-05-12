import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/providers/test_provider.dart';

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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(testHistoryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(testHistoryProvider),
        child: historyAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return const EmptyState(
                icon: Icons.history_outlined,
                title: 'История пуста',
                message: 'Вы ещё не проходили тесты',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final result = results[index];
                final passed = result.scorePercentage >= 70.0;
                final color =
                    passed ? context.successColor : context.errorColor;

                return CustomCard(
                  onTap: () => context.push('/test-result/${result.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: AppRadius.borderRadiusSm,
                        ),
                        child: Icon(
                          passed
                              ? Icons.check_circle_outline_rounded
                              : Icons.close_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
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
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(
                                result.finishedAt ?? DateTime.now(),
                              ),
                              style: AppTypography.caption.copyWith(
                                color: context.textTertiaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${result.scorePercentage.toStringAsFixed(0)}%',
                            style: AppTypography.heading4.copyWith(
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            passed ? 'Пройден' : 'Не пройден',
                            style: AppTypography.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(message: error.toString()),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
