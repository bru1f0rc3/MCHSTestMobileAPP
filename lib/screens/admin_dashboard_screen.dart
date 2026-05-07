import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/services/reports_service.dart';

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats?>((ref) async {
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
  } catch (_) {
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
        title: const Text('Администрирование'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
            onPressed: () {
              ref.read(refreshProvider.notifier).refreshAll();
              ref.invalidate(dashboardStatsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(refreshProvider.notifier).refreshAll();
          ref.invalidate(dashboardStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            statsAsync.when(
              data: (stats) => _StatsGrid(stats: stats),
              loading: () => const _StatsGrid(stats: null, loading: true),
              error: (_, __) => const _StatsGrid(stats: null),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Управление',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminTile(
              icon: Icons.people_outline,
              title: 'Пользователи',
              subtitle: 'Учётные записи, роли, блокировки',
              onTap: () => context.push('/admin-users'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AdminTile(
              icon: Icons.quiz_outlined,
              title: 'Тесты',
              subtitle: 'Создание и редактирование тестов',
              onTap: () => context.push('/admin-tests'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AdminTile(
              icon: Icons.menu_book_outlined,
              title: 'Лекции',
              subtitle: 'Загрузка и обновление материалов',
              onTap: () => context.push('/admin-lectures'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AdminTile(
              icon: Icons.assessment_outlined,
              title: 'Отчёты',
              subtitle: 'Статистика и выгрузки',
              onTap: () => context.push('/admin/reports'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats? stats;
  final bool loading;
  const _StatsGrid({required this.stats, this.loading = false});

  @override
  Widget build(BuildContext context) {
    String fmtInt(int? v) => v?.toString() ?? '—';
    String fmtScore(double? v) =>
        v == null ? '—' : '${v.toStringAsFixed(1)}%';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      children: [
        _StatTile(
          label: 'Пользователи',
          value: loading ? '…' : fmtInt(stats?.totalUsers),
          icon: Icons.people_outline,
        ),
        _StatTile(
          label: 'Тестов',
          value: loading ? '…' : fmtInt(stats?.totalTests),
          icon: Icons.quiz_outlined,
        ),
        _StatTile(
          label: 'Лекций',
          value: loading ? '…' : fmtInt(stats?.totalLectures),
          icon: Icons.menu_book_outlined,
        ),
        _StatTile(
          label: 'Средний балл',
          value: loading ? '…' : fmtScore(stats?.averageScore),
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.textTertiaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.heading2.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
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
              color: context.primaryColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.body2.copyWith(
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textTertiaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
