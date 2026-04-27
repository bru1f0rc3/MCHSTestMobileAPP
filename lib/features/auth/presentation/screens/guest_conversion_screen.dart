import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';

class GuestConversionScreen extends ConsumerStatefulWidget {
  const GuestConversionScreen({super.key});

  @override
  ConsumerState<GuestConversionScreen> createState() =>
      _GuestConversionScreenState();
}

class _GuestConversionScreenState extends ConsumerState<GuestConversionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSendingCode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _convertAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(authStateProvider.notifier)
        .convertGuestToUser(
          _usernameController.text.trim(),
          _passwordController.text,
          email: _emailController.text.trim(),
          verificationCode: _emailCodeController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _toast('Аккаунт создан, прогресс сохранён');
      context.go('/home');
    } else {
      _toast(
        ref.read(authStateProvider).error ?? 'Не удалось создать аккаунт',
        error: true,
      );
    }
  }

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      _toast('Введите email', error: true);
      return;
    }
    setState(() => _isSendingCode = true);
    final ok = await ref.read(authServiceProvider).sendVerificationCode(
          email: _emailController.text.trim(),
          purpose: 'registration',
        );
    if (!mounted) return;
    setState(() => _isSendingCode = false);
    _toast(ok ? 'Код отправлен' : 'Не удалось отправить код', error: !ok);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Создать аккаунт',
      subtitle: 'Сохраните свой прогресс и продолжайте обучение',
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              controller: _usernameController,
              label: 'Имя пользователя',
              hint: 'Латинские буквы, цифры, _',
              icon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите имя пользователя';
                if (v.length < 3) return 'Минимум 3 символа';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                  return 'Только латинские буквы, цифры и _';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@mail.ru',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите email';
                if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                  return 'Неверный формат email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _emailCodeController,
              label: 'Код из письма',
              hint: '6 цифр',
              icon: Icons.verified_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().length != 6) {
                  return 'Введите 6-значный код';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: (_isLoading || _isSendingCode) ? null : _sendCode,
                child: _isSendingCode
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Получить код'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthField(
              controller: _passwordController,
              label: 'Пароль',
              hint: 'Минимум 6 символов',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: _PasswordToggle(
                obscured: _obscurePassword,
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Введите пароль';
                if (v.length < 6) return 'Минимум 6 символов';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _confirmPasswordController,
              label: 'Подтверждение пароля',
              hint: 'Повторите пароль',
              icon: Icons.lock_reset_rounded,
              obscure: _obscureConfirm,
              suffix: _PasswordToggle(
                obscured: _obscureConfirm,
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Подтвердите пароль';
                if (v != _passwordController.text) {
                  return 'Пароли не совпадают';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Создать аккаунт',
              onPressed: _isLoading ? null : _convertAccount,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;
  const _PasswordToggle({required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 18,
        color: context.textTertiaryColor,
      ),
    );
  }
}
