import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isGuest = authState.isGuest;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            CustomCard(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isGuest 
                          ? context.warningColor.withOpacity(0.1)
                          : context.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGuest ? Icons.person_outline : Icons.person,
                      size: 40,
                      color: isGuest ? context.warningColor : context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? 'Пользователь',
                    style: AppTypography.heading3.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGuest
                          ? context.warningColor.withOpacity(0.1)
                          : user?.role == 'admin'
                              ? AppColors.accent.withOpacity(0.1)
                              : context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGuest 
                          ? 'Гость'
                          : user?.role == 'admin' 
                              ? 'Администратор' 
                              : 'Пользователь',
                      style: AppTypography.caption.copyWith(
                        color: isGuest
                            ? context.warningColor
                            : user?.role == 'admin' 
                                ? AppColors.accent 
                                : context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guest Registration Banner
            if (isGuest) ...[
              CustomCard(
                color: context.successColor.withOpacity(0.1),
                onTap: () => context.push('/guest-conversion'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: context.successColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Создать аккаунт',
                            style: AppTypography.body1.copyWith(
                              color: context.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ваш прогресс будет сохранен',
                            style: AppTypography.caption.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: context.successColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Menu Section
            Text(
              'Основное',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.history,
                    title: 'История тестов',
                    subtitle: 'Просмотр результатов',
                    onTap: () => context.push('/test-history'),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.bar_chart,
                    title: 'Статистика',
                    subtitle: 'Прогресс обучения',
                    onTap: () => context.push('/user-statistics'),
                  ),
                  if (user?.role == 'admin') ...[
                    const Divider(height: 1),
                    _MenuItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Панель администратора',
                      subtitle: 'Управление системой',
                      onTap: () => context.push('/admin-dashboard'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            Text(
              'Настройки',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Переключатель темы
                  _ThemeToggleItem(ref: ref),
                  Divider(height: 1, color: context.dividerColor),
                  if (!isGuest) ...[
                    _MenuItem(
                      icon: Icons.lock_outline,
                      title: 'Сменить пароль',
                      subtitle: 'Безопасность аккаунта',
                      onTap: () {
                        _showChangePasswordDialog(context, ref);
                      },
                    ),
                    Divider(height: 1, color: context.dividerColor),
                  ],
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    subtitle: 'Версия 1.0.0',
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CustomCard(
              onTap: () => _showLogoutDialog(context, ref),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: context.errorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Выйти из аккаунта',
                      style: AppTypography.body1.copyWith(
                        color: context.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.errorColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Сменить пароль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Текущий пароль',
                  hintText: 'Введите текущий пароль',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый пароль',
                  hintText: 'Введите новый пароль',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Подтвердите пароль',
                  hintText: 'Введите пароль еще раз',
                ),
              ),
              if (isLoading) ...[                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (oldPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Введите текущий пароль')),
                        );
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Новый пароль должен быть не менее 6 символов')),
                        );
                        return;
                      }
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароли не совпадают')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final authService = ref.read(authServiceProvider);
                        final success = await authService.changePassword(
                          oldPasswordController.text,
                          newPasswordController.text,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Пароль успешно изменен'
                                  : 'Ошибка смены пароля'),
                              backgroundColor:
                                  success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'МЧС России',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.local_fire_department,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('Система профессиональной подготовки'),
        const SizedBox(height: 16),
        const Text('© 2026 МЧС России'),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
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
                    style: AppTypography.caption.copyWith(
                      color: context.textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.textTertiaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет переключателя темы
class _ThemeToggleItem extends ConsumerWidget {
  final WidgetRef ref;
  
  const _ThemeToggleItem({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDark;

    return Padding(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: context.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Темная тема',
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Включена' : 'Выключена',
                  style: AppTypography.caption.copyWith(
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
            activeColor: context.primaryColor,
          ),
        ],
      ),
    );
  }
}