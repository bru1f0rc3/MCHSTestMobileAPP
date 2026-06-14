import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/auth_scaffold.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';

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
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showNameFields = false;

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

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authStateProvider.notifier).register(
          _usernameController.text.trim(),
          _passwordController.text,
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

  String? _optionalMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < minLength) {
      return '$fieldName: минимум $minLength символов';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Регистрация',
      subtitle: 'Достаточно логина и пароля — ФИО можно добавить позже',
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              controller: _usernameController,
              label: 'Имя пользователя',
              hint: 'Минимум 3 символа',
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
              suffix: _EyeButton(
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
              suffix: _EyeButton(
                obscured: _obscureConfirm,
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordController.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            _OptionalNameSection(
              expanded: _showNameFields,
              onToggle: () =>
                  setState(() => _showNameFields = !_showNameFields),
              lastNameController: _lastNameController,
              firstNameController: _firstNameController,
              patronymicController: _patronymicController,
              optionalMinLength: _optionalMinLength,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Зарегистрироваться',
              onPressed: authState.isLoading ? null : _handleRegister,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
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

class _OptionalNameSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController patronymicController;
  final String? Function(String?, int, String) optionalMinLength;

  const _OptionalNameSection({
    required this.expanded,
    required this.onToggle,
    required this.lastNameController,
    required this.firstNameController,
    required this.patronymicController,
    required this.optionalMinLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: AppRadius.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: context.textSecondaryColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Указать ФИО (необязательно)',
                  style: AppTypography.body2.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          AuthField(
            controller: lastNameController,
            label: 'Фамилия',
            hint: 'Иванов',
            validator: (v) => optionalMinLength(v, 2, 'Фамилия'),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthField(
            controller: firstNameController,
            label: 'Имя',
            hint: 'Иван',
            validator: (v) => optionalMinLength(v, 2, 'Имя'),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthField(
            controller: patronymicController,
            label: 'Отчество',
            hint: 'Иванович',
            validator: (v) => optionalMinLength(v, 2, 'Отчество'),
          ),
        ],
      ],
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
