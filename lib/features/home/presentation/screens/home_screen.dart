import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';
import 'package:mchs_mobile_app/features/admin/data/services/reports_service.dart';

final homeStatisticsProvider =
    FutureProvider.autoDispose<UserStatisticsDto?>((ref) async {
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
    final user = ref.watch(authStateProvider).user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Панель администратора',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin-dashboard'),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _Greeting(name: user?.username ?? 'Спасатель'),
          const SizedBox(height: AppSpacing.xl),
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(homeStatisticsProvider);
              return statsAsync.when(
                data: (s) => _StatsRow(
                  completed: s?.testsCompleted ?? 0,
                  passed: s?.testsPassed ?? 0,
                  score: s?.averageScore ?? 0,
                ),
                loading: () => const _StatsRow(
                  completed: 0,
                  passed: 0,
                  score: 0,
                  isLoading: true,
                ),
                error: (_, __) =>
                    const _StatsRow(completed: 0, passed: 0, score: 0),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Разделы',
            style: AppTypography.heading4.copyWith(
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuTile(
            icon: Icons.menu_book_outlined,
            title: 'Лекции',
            subtitle: 'База знаний и методические материалы',
            onTap: () => context.go('/lectures'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MenuTile(
            icon: Icons.quiz_outlined,
            title: 'Тесты',
            subtitle: 'Проверка знаний по разделам',
            onTap: () => context.go('/tests'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MenuTile(
            icon: Icons.history_edu_outlined,
            title: 'История',
            subtitle: 'Пройденные тесты и результаты',
            onTap: () => context.push('/test-history'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Профиль',
            subtitle: 'Настройки и статистика',
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Добро пожаловать',
          style: AppTypography.body2.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: AppTypography.heading1.copyWith(
            color: context.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completed;
  final int passed;
  final double score;
  final bool isLoading;
  const _StatsRow({
    required this.completed,
    required this.passed,
    required this.score,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Пройдено',
              value: '$completed',
              isLoading: isLoading,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              label: 'Сдано',
              value: '$passed',
              isLoading: isLoading,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              label: 'Средний',
              value: '${score.toStringAsFixed(0)}%',
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: context.borderColor,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  const _StatItem({
    required this.label,
    required this.value,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            value,
            style: AppTypography.heading3.copyWith(
              color: context.textPrimaryColor,
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceColor,
      borderRadius: AppRadius.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(color: context.borderColor),
          ),
          child: Padding(
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
                  child: Icon(icon, size: 20, color: context.primaryColor),
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
          ),
        ),
      ),
    );
  }
}
