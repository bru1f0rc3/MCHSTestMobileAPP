import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/admin/data/services/reports_service.dart';

/// Dashboard Statistics Provider with version-based refresh
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats?>((ref) async {
  // Watch all relevant versions for auto-refresh
  ref.watch(statisticsVersionProvider);
  ref.watch(testsVersionProvider);
  ref.watch(lecturesVersionProvider);
  ref.watch(usersVersionProvider);
  
  try {
    final service = ref.watch(reportsServiceProvider);
    final response = await service.getOverallStatistics();
    if (response.success && response.data != null) {
      final data = response.data!;
      return DashboardStats(
        totalUsers: data.totalUsers,
        totalTests: data.totalTests,
        totalLectures: data.totalLectures,
        averageScore: data.averageScore,
      );
    }
    return null;
  } catch (e) {
    return null;
  }
});

class DashboardStats {
  final int totalUsers;
  final int totalTests;
  final int totalLectures;
  final double averageScore;

  DashboardStats({
    required this.totalUsers,
    required this.totalTests,
    required this.totalLectures,
    required this.averageScore,
  });
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Панель администратора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(refreshProvider.notifier).refreshAll();
              ref.invalidate(dashboardStatsProvider);
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(refreshProvider.notifier).refreshAll();
          ref.invalidate(dashboardStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Добро пожаловать',
                      style: AppTypography.body2.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Панель администратора',
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Management Sections
              Text(
                'Управление системой',
                style: AppTypography.heading4.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _AdminCard(
                      icon: Icons.people,
                      title: 'Пользователи',
                      subtitle: 'Управление',
                      color: AppColors.primary,
                      onTap: () => context.push('/admin-users'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AdminCard(
                      icon: Icons.quiz,
                      title: 'Тесты',
                      subtitle: 'Управление',
                      color: AppColors.accent,
                      onTap: () => context.push('/admin-tests'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _AdminCard(
                      icon: Icons.book,
                      title: 'Лекции',
                      subtitle: 'Управление',
                      color: AppColors.info,
                      onTap: () => context.push('/admin-lectures'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AdminCard(
                      icon: Icons.assessment,
                      title: 'Отчеты',
                      subtitle: 'Статистика',
                      color: AppColors.success,
                      onTap: () => context.push('/admin/reports'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Stats
              Text(
                'Быстрая статистика',
                style: AppTypography.heading4.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) {
                  return CustomCard(
                    child: Column(
                      children: [
                        _StatRow(
                          icon: Icons.people,
                          label: 'Всего пользователей',
                          value: stats?.totalUsers.toString() ?? '-',
                          color: AppColors.primary,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          icon: Icons.quiz,
                          label: 'Всего тестов',
                          value: stats?.totalTests.toString() ?? '-',
                          color: AppColors.accent,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          icon: Icons.book,
                          label: 'Всего лекций',
                          value: stats?.totalLectures.toString() ?? '-',
                          color: AppColors.info,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          icon: Icons.trending_up,
                          label: 'Средний балл',
                          value: stats != null
                              ? '${stats.averageScore.toStringAsFixed(1)}%'
                              : '-',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => CustomCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (error, stack) => CustomCard(
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.people,
                        label: 'Всего пользователей',
                        value: '-',
                        color: AppColors.primary,
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        icon: Icons.quiz,
                        label: 'Всего тестов',
                        value: '-',
                        color: AppColors.accent,
                      ),
                      const Divider(height: 24),
                      _StatRow(
                        icon: Icons.book,
                        label: 'Всего лекций',
                        value: '-',
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
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
