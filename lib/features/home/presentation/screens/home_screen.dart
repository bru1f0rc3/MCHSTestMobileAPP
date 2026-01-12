import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';
import 'package:mchs_mobile_app/features/admin/data/services/reports_service.dart';

/// Provider for home screen statistics
final homeStatisticsProvider = FutureProvider.autoDispose<UserStatisticsDto?>((ref) async {
  try {
    final service = ref.watch(reportsServiceProvider);
    final response = await service.getMyStatistics();
    return response.data;
  } catch (e) {
    return null;
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('МЧС России'),
        actions: [
          if (user?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.push('/admin-dashboard'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.borderRadiusLg,
                boxShadow: AppShadows.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Добро пожаловать!',
                              style: AppTypography.body2.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.username ?? 'Пользователь',
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Система профессиональной подготовки',
                    style: AppTypography.body2.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Быстрый доступ',
              style: AppTypography.heading3.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.book,
                    title: 'Лекции',
                    subtitle: 'Изучение материалов',
                    color: AppColors.primary,
                    onTap: () => context.go('/lectures'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.quiz,
                    title: 'Тесты',
                    subtitle: 'Проверка знаний',
                    color: AppColors.accent,
                    onTap: () => context.go('/tests'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.history,
                    title: 'История',
                    subtitle: 'Результаты тестов',
                    color: AppColors.info,
                    onTap: () => context.push('/test-history'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person,
                    title: 'Профиль',
                    subtitle: 'Настройки',
                    color: AppColors.success,
                    onTap: () => context.go('/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stats Section
            if (user != null) ...[
              Text(
                'Статистика',
                style: AppTypography.heading3.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final statsAsync = ref.watch(homeStatisticsProvider);
                  return statsAsync.when(
                    data: (stats) {
                      return CustomCard(
                        child: Column(
                          children: [
                            _StatRow(
                              icon: Icons.check_circle,
                              label: 'Пройдено тестов',
                              value: '${stats?.testsCompleted ?? 0}',
                              color: AppColors.success,
                            ),
                            const Divider(height: 24),
                            _StatRow(
                              icon: Icons.trending_up,
                              label: 'Средний балл',
                              value: '${stats?.averageScore.toStringAsFixed(0) ?? 0}%',
                              color: AppColors.info,
                            ),
                            const Divider(height: 24),
                            _StatRow(
                              icon: Icons.school,
                              label: 'Сдано тестов',
                              value: '${stats?.testsPassed ?? 0}',
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => CustomCard(
                      child: Column(
                        children: [
                          _StatRow(
                            icon: Icons.check_circle,
                            label: 'Пройдено тестов',
                            value: '...',
                            color: AppColors.success,
                          ),
                          const Divider(height: 24),
                          _StatRow(
                            icon: Icons.trending_up,
                            label: 'Средний балл',
                            value: '...',
                            color: AppColors.info,
                          ),
                          const Divider(height: 24),
                          _StatRow(
                            icon: Icons.school,
                            label: 'Сдано тестов',
                            value: '...',
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    error: (_, __) => CustomCard(
                      child: Column(
                        children: [
                          _StatRow(
                            icon: Icons.check_circle,
                            label: 'Пройдено тестов',
                            value: '0',
                            color: AppColors.success,
                          ),
                          const Divider(height: 24),
                          _StatRow(
                            icon: Icons.trending_up,
                            label: 'Средний балл',
                            value: '0%',
                            color: AppColors.info,
                          ),
                          const Divider(height: 24),
                          _StatRow(
                            icon: Icons.school,
                            label: 'Сдано тестов',
                            value: '0',
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
          style: AppTypography.heading4.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
