import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

class TestDetailScreen extends ConsumerWidget {
  final int testId;

  const TestDetailScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(testDetailProvider(testId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('О тесте')),
      body: testAsync.when(
        data: (test) {
          if (test == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Тест не найден',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                test.title,
                style: AppTypography.heading2.copyWith(
                  color: context.textPrimaryColor,
                ),
              ),
              if (test.description != null &&
                  test.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  test.description!,
                  style: AppTypography.body1.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              CustomCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Количество вопросов',
                      value: '${test.questions.length}',
                    ),
                    Divider(height: 1, color: context.dividerColor),
                    _InfoRow(
                      icon: Icons.check_circle_outline,
                      label: 'Проходной балл',
                      value: '${test.passingScore}%',
                    ),
                    Divider(height: 1, color: context.dividerColor),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Время',
                      value: test.timeLimitMinutes != null
                          ? '${test.timeLimitMinutes} мин'
                          : 'Без ограничений',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Вопросы',
                style: AppTypography.heading4.copyWith(
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...test.questions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CustomCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                context.primaryColor.withValues(alpha: 0.10),
                            borderRadius: AppRadius.borderRadiusSm,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTypography.caption.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.questionText,
                                style: AppTypography.body1.copyWith(
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.value.answers.length} вариантов',
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                text: 'Начать тест',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push('/test-taking/$testId'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(message: error.toString()),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: context.textSecondaryColor, size: 18),
          const SizedBox(width: AppSpacing.md),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
