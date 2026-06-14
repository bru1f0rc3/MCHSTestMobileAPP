import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/providers/theme_provider.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/models/report_model.dart';
import 'package:mchs_mobile_app/services/reports_service.dart';
import 'package:mchs_mobile_app/services/auth_service.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';

final profileStatsProvider =
    FutureProvider.autoDispose<UserStatisticsDto?>((ref) async {
      try {
        final service = ref.watch(reportsServiceProvider);
        final response = await service.getMyStatistics();
        return response.data;
      } catch (_) {
        return null;
      }
    });

final currentProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      try {
        return await ref.watch(authServiceProvider).getCurrentUser();
      } catch (_) {
        return null;
      }
    });

String _composeFullName(Map<String, dynamic>? p) {
  if (p == null) return '';
  final parts = <String>[];
  for (final k in ['lastName', 'firstName', 'patronymic']) {
    final v = (p[k] as String?)?.trim();
    if (v != null && v.isNotEmpty) parts.add(v);
  }
  return parts.join(' ');
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isGuest = authState.isGuest;
    final isDark = ref.watch(themeProvider).isDark;
    final profileAsync = isGuest
        ? const AsyncValue<Map<String, dynamic>?>.data(null)
        : ref.watch(currentProfileProvider);
    final fullName = _composeFullName(profileAsync.asData?.value);
    final roleLabel = isGuest
        ? 'Гостевой режим'
        : (user?.isSuperAdmin ?? false
              ? 'Суперадминистратор'
              : (user?.isAdmin ?? false
                    ? 'Администратор'
                    : 'Пользователь'));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _ProfileCard(
            name: fullName.isNotEmpty
                ? fullName
                : (user?.username ?? (isGuest ? 'Гость' : 'Пользователь')),
            username: user?.username ?? '',
            roleLabel: roleLabel,
            isGuest: isGuest,
            isAdmin: !isGuest && (user?.isAdmin ?? false),
          ),
          if (!isGuest) ...[
            const SizedBox(height: AppSpacing.lg),
            Consumer(
              builder: (context, ref, _) {
                final statsAsync = ref.watch(profileStatsProvider);
                return statsAsync.when(
                  data: (s) {
                    if (s == null) return const SizedBox.shrink();
                    return _StatsRow(
                      completed: s.testsCompleted,
                      passed: s.testsPassed,
                      score: s.averageScore,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Тёмная тема',
                subtitle: isDark ? 'Включена' : 'Выключена',
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              if (!isGuest) ...[
                _SettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Личные данные',
                  subtitle: 'ФИО, пароль',
                  onTap: () => context.push('/profile-security'),
                ),
                _SettingsTile(
                  icon: Icons.history_edu_outlined,
                  title: 'История тестов',
                  subtitle: 'Все пройденные тесты',
                  onTap: () => context.push('/test-history'),
                ),
                _SettingsTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Моя статистика',
                  subtitle: 'Детальный прогресс',
                  onTap: () => context.push('/user-statistics'),
                ),
              ],
              if (isGuest)
                _SettingsTile(
                  icon: Icons.person_add_outlined,
                  title: 'Зарегистрироваться',
                  subtitle: 'Сохраните свой прогресс',
                  onTap: () => context.push('/guest-conversion'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isGuest)
            ElevatedButton.icon(
              onPressed: () async {
                final router = GoRouter.of(context);
                await ref.read(authStateProvider.notifier).logout();
                router.go('/login');
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Войти в аккаунт'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.errorColor,
                side: BorderSide(
                  color: context.errorColor.withValues(alpha: 0.5),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Выйти из аккаунта'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы будете перенаправлены на экран входа.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(authStateProvider.notifier).logout();
    router.go('/login');
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String username;
  final String roleLabel;
  final bool isGuest;
  final bool isAdmin;

  const _ProfileCard({
    required this.name,
    required this.username,
    required this.roleLabel,
    required this.isGuest,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Icon(
              isGuest ? Icons.person_off_outlined : Icons.person_outline,
              size: 28,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.heading4.copyWith(
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: AppTypography.body2.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? context.primaryColor.withValues(alpha: 0.10)
                            : context.surfaceVariantColor,
                        borderRadius: AppRadius.borderRadiusSm,
                      ),
                      child: Text(
                        roleLabel,
                        style: AppTypography.caption.copyWith(
                          color: isAdmin
                              ? context.primaryColor
                              : context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completed;
  final int passed;
  final double score;
  const _StatsRow({
    required this.completed,
    required this.passed,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(child: _item(context, 'Тестов', '$completed')),
          _divider(context),
          Expanded(child: _item(context, 'Сдано', '$passed')),
          _divider(context),
          Expanded(
            child: _item(context, 'Средний', '${score.toStringAsFixed(0)}%'),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(height: 28, width: 1, color: context.borderColor);
  }

  Widget _item(BuildContext context, String label, String value) {
    return Column(
      children: [
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

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 1, color: context.dividerColor));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      onTap: onTap,
      leading: Icon(icon, color: context.textSecondaryColor, size: 22),
      title: Text(
        title,
        style: AppTypography.body1.copyWith(
          color: context.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: context.textSecondaryColor,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: context.textTertiaryColor,
            size: 20,
          ),
    );
  }
}
