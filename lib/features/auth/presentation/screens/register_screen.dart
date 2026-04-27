import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSendingCode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }
    final success = await ref.read(authStateProvider.notifier).register(
          _usernameController.text.trim(),
          _passwordController.text,
          email: _emailController.text.trim(),
          verificationCode: _emailCodeController.text.trim(),
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      _showError(ref.read(authStateProvider).error ?? 'Ошибка регистрации');
    }
  }

  Future<void> _sendEmailCode() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Сначала укажите email');
      return;
    }
    setState(() => _isSendingCode = true);
    final ok = await ref.read(authServiceProvider).sendVerificationCode(
          email: _emailController.text.trim(),
          purpose: 'registration',
        );
    if (!mounted) return;
    setState(() => _isSendingCode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Код отправлен на email' : 'Не удалось отправить код'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Регистрация',
      subtitle: 'Создайте аккаунт в обучающем портале',
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionLabel('ФИО'),
            AuthField(
              controller: _lastNameController,
              label: 'Фамилия',
              hint: 'Иванов',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите фамилию';
                if (v.trim().length < 2) return 'Минимум 2 символа';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _firstNameController,
              label: 'Имя',
              hint: 'Иван',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите имя';
                if (v.trim().length < 2) return 'Минимум 2 символа';
                return null;
              },
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
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Учётные данные'),
            AuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@mail.ru',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите email';
                final re = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
                if (!re.hasMatch(v.trim())) return 'Неверный формат email';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _emailCodeController,
              label: 'Код подтверждения',
              hint: '6 цифр из письма',
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
                onPressed: (authState.isLoading || _isSendingCode)
                    ? null
                    : _sendEmailCode,
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
              controller: _usernameController,
              label: 'Имя пользователя',
              hint: 'Минимум 3 символа',
              icon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Введите имя пользователя';
                }
                if (v.trim().length < 3) return 'Минимум 3 символа';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthField(
              controller: _passwordController,
              label: 'Пароль',
              hint: 'Минимум 6 символов',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: _EyeButton(
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
              suffix: _EyeButton(
                obscured: _obscureConfirm,
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Подтвердите пароль';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Зарегистрироваться',
              onPressed: authState.isLoading ? null : _handleRegister,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Уже есть аккаунт? ',
                    style: AppTypography.body2.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Войти',
                      style: AppTypography.body2.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: context.textTertiaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;
  const _EyeButton({required this.obscured, required this.onTap});

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
