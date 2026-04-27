import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _confirmFormKey = GlobalKey<FormState>();
  final _loginOrEmailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _codeSent = false;
  String? _maskedEmail;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _loginOrEmailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _requestCode() async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final masked = await ref
        .read(authServiceProvider)
        .requestForgotPasswordCode(_loginOrEmailController.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _maskedEmail = masked;
      _codeSent = masked != null && masked.isNotEmpty;
    });
    _toast(
      _codeSent
          ? 'Код отправлен на $_maskedEmail'
          : 'Не удалось отправить код',
      error: !_codeSent,
    );
  }

  Future<void> _confirmReset() async {
    if (!(_confirmFormKey.currentState?.validate() ?? false)) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _toast('Пароли не совпадают', error: true);
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(authServiceProvider).confirmForgotPassword(
          loginOrEmail: _loginOrEmailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      _toast('Пароль восстановлен');
      context.go('/login');
    } else {
      _toast('Неверный код или данные', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Восстановление',
      subtitle: 'Введите логин или email для получения кода',
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _requestFormKey,
            child: AuthField(
              controller: _loginOrEmailController,
              label: 'Логин или email',
              hint: 'user или user@mail.ru',
              icon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Введите логин или email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'Получить код',
            onPressed: _loading ? null : _requestCode,
            isLoading: _loading,
          ),
          if (_maskedEmail != null && _maskedEmail!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Код отправлен на $_maskedEmail',
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_codeSent) ...[
            const SizedBox(height: AppSpacing.xl),
            Form(
              key: _confirmFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    controller: _codeController,
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
                  const SizedBox(height: AppSpacing.md),
                  AuthField(
                    controller: _newPasswordController,
                    label: 'Новый пароль',
                    hint: 'Минимум 6 символов',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureNew,
                    suffix: _Eye(
                      obscured: _obscureNew,
                      onTap: () =>
                          setState(() => _obscureNew = !_obscureNew),
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
                    hint: 'Повторите новый пароль',
                    icon: Icons.lock_reset_rounded,
                    obscure: _obscureConfirm,
                    suffix: _Eye(
                      obscured: _obscureConfirm,
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Повторите пароль';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CustomButton(
                    text: 'Сменить пароль',
                    onPressed: _loading ? null : _confirmReset,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;
  const _Eye({required this.obscured, required this.onTap});

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
