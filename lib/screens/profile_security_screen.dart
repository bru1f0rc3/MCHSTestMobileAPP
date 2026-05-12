import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/services/auth_service.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';
import 'package:mchs_mobile_app/screens/profile_screen.dart';

class ProfileSecurityScreen extends ConsumerStatefulWidget {
  const ProfileSecurityScreen({super.key});

  @override
  ConsumerState<ProfileSecurityScreen> createState() =>
      _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends ConsumerState<ProfileSecurityScreen> {
  final _fioFormKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  bool _loadingFio = false;
  bool _profilePrefilled = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, maxLines: 6, softWrap: true),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _saveFio() async {
    if (!(_fioFormKey.currentState?.validate() ?? false)) return;
    setState(() => _loadingFio = true);
    final result = await ref.read(authServiceProvider).updateProfile(
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loadingFio = false);
    if (result != null) {
      ref.invalidate(currentProfileProvider);
      _showMessage('Личные данные обновлены', ok: true);
    } else {
      _showMessage('Не удалось сохранить личные данные');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    profileAsync.whenData((profile) {
      if (profile == null || _profilePrefilled) return;
      _profilePrefilled = true;
      _lastNameController.text = (profile['lastName'] as String?) ?? '';
      _firstNameController.text = (profile['firstName'] as String?) ?? '';
      _patronymicController.text = (profile['patronymic'] as String?) ?? '';
    });

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Личные данные и безопасность')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              _section(
                context,
                title: 'Личные данные (ФИО)',
                child: Form(
                  key: _fioFormKey,
                  child: Column(
                    children: [
                      _field(
                        context,
                        _lastNameController,
                        'Фамилия',
                        validator: (v) =>
                            Validators.minLength(v, 2, 'Фамилия'),
                      ),
                      const SizedBox(height: 10),
                      _field(
                        context,
                        _firstNameController,
                        'Имя',
                        validator: (v) => Validators.minLength(v, 2, 'Имя'),
                      ),
                      const SizedBox(height: 10),
                      _field(
                        context,
                        _patronymicController,
                        'Отчество (необязательно)',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (v.trim().length < 2) return 'Минимум 2 символа';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Сохранить ФИО',
                        onPressed: _loadingFio ? null : _saveFio,
                        isLoading: _loadingFio,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Смена пароля',
                child: CustomButton(
                  text: 'Сменить пароль',
                  icon: Icons.lock_outline_rounded,
                  onPressed: _openChangePasswordModal,
                ),
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Удаление аккаунта',
                child: CustomButton(
                  text: 'Удалить аккаунт',
                  icon: Icons.delete_outline_rounded,
                  backgroundColor: AppColors.error,
                  onPressed: _confirmDeleteAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChangePasswordModal() async {
    final auth = ref.read(authServiceProvider);
    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final pass1Ctrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    bool loading = false;
    bool obscureOld = true;
    bool obscure1 = true;
    bool obscure2 = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false)) return;
            setModal(() => loading = true);
            final ok = await auth.changePassword(
              oldCtrl.text,
              pass1Ctrl.text,
            );
            if (!context.mounted) return;
            setModal(() => loading = false);
            if (ok) Navigator.of(ctx).pop();
            _showMessage(
              ok ? 'Пароль успешно изменён' : 'Неверный текущий пароль',
              ok: ok,
            );
          }

          return _modalFrame(
            context: ctx,
            title: 'Смена пароля',
            icon: Icons.lock,
            subtitle: 'Введите текущий пароль и новый пароль',
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  _field(
                    ctx,
                    oldCtrl,
                    'Текущий пароль',
                    obscure: obscureOld,
                    onToggle: () => setModal(() => obscureOld = !obscureOld),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Введите пароль' : null,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    ctx,
                    pass1Ctrl,
                    'Новый пароль',
                    obscure: obscure1,
                    onToggle: () => setModal(() => obscure1 = !obscure1),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    ctx,
                    pass2Ctrl,
                    'Повторите пароль',
                    obscure: obscure2,
                    onToggle: () => setModal(() => obscure2 = !obscure2),
                    validator: (v) =>
                        Validators.confirmPassword(v, pass1Ctrl.text),
                  ),
                ],
              ),
            ),
            loading: loading,
            primaryText: 'Сохранить',
            onPrimary: submit,
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Это действие необратимо. Все ваши данные и история тестов будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final ok = await ref.read(authServiceProvider).deleteAccount();
    if (!mounted) return;
    if (!ok) {
      _showMessage('Не удалось удалить аккаунт');
      return;
    }
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
    _showMessage('Аккаунт удалён', ok: true);
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body1.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.surfaceVariantColor,
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggle,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
      ),
    );
  }

  Widget _modalFrame({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String subtitle,
    required Widget body,
    required bool loading,
    required String primaryText,
    required VoidCallback onPrimary,
  }) {
    return Dialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.heading3.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: context.surfaceVariantColor,
                  child: Icon(icon, color: context.primaryColor, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                body,
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : onPrimary,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(primaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
