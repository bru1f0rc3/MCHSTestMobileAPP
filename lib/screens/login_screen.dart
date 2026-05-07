import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/models/user_model.dart';
import 'package:mchs_mobile_app/services/auth_service.dart';
import 'package:mchs_mobile_app/widgets/auth_scaffold.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _checkingDevice = true;
  GuestStatusResponse? _deviceStatus;

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
  }

  Future<void> _loadDeviceStatus() async {
    final notifier = ref.read(authStateProvider.notifier);
    final deviceId = await notifier.getDeviceId();
    final status = await ref.read(authServiceProvider).getGuestStatus(deviceId);
    if (!mounted) return;
    setState(() {
      _deviceStatus = status;
      _checkingDevice = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authStateProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      _showError(ref.read(authStateProvider).error ?? 'Ошибка входа');
    }
  }

  Future<void> _handleGuestLogin() async {
    final success = await ref.read(authStateProvider.notifier).loginAsGuest();
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      _showError('Не удалось войти как гость');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 6, softWrap: true),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final hasAccount = (_deviceStatus?.hasExistingAccount ?? false) &&
        !(_deviceStatus?.isGuestAccount ?? false);

    return AuthScaffold(
      title: 'С возвращением',
      subtitle: 'Войдите, чтобы продолжить обучение',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              controller: _usernameController,
              label: 'Логин или email',
              hint: 'user или user@mail.ru',
              icon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Введите имя пользователя';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _passwordController,
              label: 'Пароль',
              hint: 'Введите пароль',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: context.textTertiaryColor,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите пароль';
                if (v.length < 4) return 'Минимум 4 символа';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text('Забыли пароль?'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomButton(
              text: 'Войти',
              onPressed: authState.isLoading ? null : _handleLogin,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              text: _checkingDevice
                  ? 'Проверка устройства...'
                  : (hasAccount ? 'Войти в существующий' : 'Войти как гость'),
              isOutlined: true,
              onPressed: (authState.isLoading || _checkingDevice)
                  ? null
                  : _handleGuestLogin,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Нет аккаунта? ',
                  style: AppTypography.body2.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    'Зарегистрироваться',
                    style: AppTypography.body2.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
