import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/auth_scaffold.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';

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
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 6, softWrap: true),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
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
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
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
              controller: _lastNameController,
              label: 'Фамилия',
              hint: 'Иванов',
              validator: (v) => Validators.minLength(v, 2, 'Фамилия'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _firstNameController,
              label: 'Имя',
              hint: 'Иван',
              validator: (v) => Validators.minLength(v, 2, 'Имя'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _patronymicController,
              label: 'Отчество',
              hint: 'Иванович (необязательно)',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length < 2) return 'Минимум 2 символа';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _usernameController,
              label: 'Имя пользователя',
              hint: 'Латинские буквы, цифры, _',
              icon: Icons.alternate_email_rounded,
              validator: Validators.username,
            ),
            const SizedBox(height: AppSpacing.md),
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
              validator: Validators.password,
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
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordController.text),
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
