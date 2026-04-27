import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/features/auth/data/services/auth_service.dart';
import 'package:mchs_mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mchs_mobile_app/features/profile/presentation/screens/profile_screen.dart';

class ProfileSecurityScreen extends ConsumerStatefulWidget {
  const ProfileSecurityScreen({super.key});

  @override
  ConsumerState<ProfileSecurityScreen> createState() =>
      _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends ConsumerState<ProfileSecurityScreen> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  bool _loadingFio = false;

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
        content: Text(text),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _saveFio() async {
    setState(() => _loadingFio = true);
    final result = await ref
        .read(authServiceProvider)
        .updateProfile(
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
      if (profile == null) return;
      if (_lastNameController.text.isEmpty &&
          _firstNameController.text.isEmpty &&
          _patronymicController.text.isEmpty) {
        _lastNameController.text = (profile['lastName'] as String?) ?? '';
        _firstNameController.text = (profile['firstName'] as String?) ?? '';
        _patronymicController.text = (profile['patronymic'] as String?) ?? '';
      }
    });

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Личные данные и безопасность')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _section(
              context,
              title: '1) Личные данные (ФИО)',
              child: Column(
                children: [
                  _field(context, _lastNameController, 'Фамилия'),
                  const SizedBox(height: 10),
                  _field(context, _firstNameController, 'Имя'),
                  const SizedBox(height: 10),
                  _field(context, _patronymicController, 'Отчество'),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Сохранить ФИО',
                    onPressed: _loadingFio ? null : _saveFio,
                    isLoading: _loadingFio,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
              context,
              title: '2) Смена пароля',
              child: CustomButton(
                text: 'Открыть окно смены пароля',
                icon: Icons.lock_outline_rounded,
                onPressed: _openChangePasswordModal,
              ),
            ),
            const SizedBox(height: 14),
            _section(
              context,
              title: '3) Смена email',
              child: CustomButton(
                text: 'Открыть окно смены email',
                icon: Icons.alternate_email_rounded,
                onPressed: _openChangeEmailModal,
              ),
            ),
            const SizedBox(height: 14),
            _section(
              context,
              title: '4) Удаление аккаунта',
              child: CustomButton(
                text: 'Удалить аккаунт',
                icon: Icons.delete_outline_rounded,
                backgroundColor: AppColors.error,
                onPressed: _openDeleteAccountModal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChangePasswordModal() async {
    final auth = ref.read(authServiceProvider);
    final codeCtrl = TextEditingController();
    final oldCtrl = TextEditingController();
    final pass1Ctrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    bool loading = false;
    bool codeAccepted = false;
    String? maskedEmail;
    bool obscure1 = true;
    bool obscure2 = true;
    bool obscureOld = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> sendCode() async {
            setModal(() => loading = true);
            final masked = await auth.requestChangePasswordCode();
            if (!context.mounted) return;
            setModal(() {
              loading = false;
              maskedEmail = (masked != null && masked.isNotEmpty)
                  ? masked
                  : null;
            });
            _showMessage(
              maskedEmail != null
                  ? 'Код отправлен на $maskedEmail'
                  : 'Не удалось отправить код',
              ok: maskedEmail != null,
            );
          }

          Future<void> verifyCodeAndNext() async {
            if (codeCtrl.text.trim().length != 6) {
              _showMessage('Введите 6-значный код');
              return;
            }
            setModal(() => codeAccepted = true);
          }

          Future<void> submitPassword() async {
            if (oldCtrl.text.isEmpty) {
              _showMessage('Введите текущий пароль');
              return;
            }
            if (pass1Ctrl.text.length < 6) {
              _showMessage('Новый пароль: минимум 6 символов');
              return;
            }
            if (pass1Ctrl.text != pass2Ctrl.text) {
              _showMessage('Пароли не совпадают');
              return;
            }
            setModal(() => loading = true);
            final ok = await auth.changePassword(
              oldCtrl.text,
              pass1Ctrl.text,
              verificationCode: codeCtrl.text.trim(),
            );
            if (!context.mounted) return;
            setModal(() => loading = false);
            if (ok) {
              Navigator.of(ctx).pop();
            }
            _showMessage(
              ok ? 'Пароль успешно изменён' : 'Не удалось сменить пароль',
              ok: ok,
            );
          }

          return _modalFrame(
            context: ctx,
            title: codeAccepted
                ? 'Установите новый пароль'
                : 'Верификация безопасности',
            icon: codeAccepted ? Icons.lock : Icons.mark_email_read_outlined,
            subtitle: codeAccepted
                ? 'Пожалуйста, установите новый надёжный пароль'
                : 'Введите код подтверждения из эл. письма для проверки личности'
                      '${maskedEmail != null ? '\n$maskedEmail' : ''}',
            body: Column(
              children: [
                if (!codeAccepted) ...[
                  _field(ctx, codeCtrl, 'Код подтверждения'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : sendCode,
                      child: const Text('Отправить'),
                    ),
                  ),
                ] else ...[
                  _field(
                    ctx,
                    oldCtrl,
                    'Текущий пароль',
                    obscure: obscureOld,
                    onToggle: () {
                      setModal(() => obscureOld = !obscureOld);
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    ctx,
                    pass1Ctrl,
                    'Введите пароль',
                    obscure: obscure1,
                    onToggle: () {
                      setModal(() => obscure1 = !obscure1);
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    ctx,
                    pass2Ctrl,
                    'Повторите пароль',
                    obscure: obscure2,
                    onToggle: () {
                      setModal(() => obscure2 = !obscure2);
                    },
                  ),
                ],
              ],
            ),
            loading: loading,
            primaryText: codeAccepted ? 'ОК' : 'Далее',
            onPrimary: codeAccepted ? submitPassword : verifyCodeAndNext,
          );
        },
      ),
    );
  }

  Future<void> _openChangeEmailModal() async {
    final auth = ref.read(authServiceProvider);
    final currentCodeCtrl = TextEditingController();
    final newEmailCtrl = TextEditingController();
    final newCodeCtrl = TextEditingController();

    bool loading = false;
    int step = 1;
    String? maskedCurrent;
    String? maskedNew;
    bool newCodeSent = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> sendCurrentCode() async {
            setModal(() => loading = true);
            final masked = await auth.requestCurrentEmailChangeCode();
            if (!context.mounted) return;
            setModal(() {
              loading = false;
              maskedCurrent = (masked != null && masked.isNotEmpty)
                  ? masked
                  : null;
            });
            _showMessage(
              maskedCurrent != null
                  ? 'Код отправлен на $maskedCurrent'
                  : 'Не удалось отправить код',
              ok: maskedCurrent != null,
            );
          }

          Future<void> sendNewCodeAndProceed() async {
            if (currentCodeCtrl.text.trim().length != 6) {
              _showMessage('Введите код с текущей почты');
              return;
            }
            if (step == 1) {
              setModal(() => loading = true);
              final ok = await auth.verifyCurrentEmailCode(
                currentEmailCode: currentCodeCtrl.text.trim(),
              );
              if (!context.mounted) return;
              setModal(() {
                loading = false;
                if (ok) step = 2;
              });
              _showMessage(
                ok
                    ? 'Текущая почта подтверждена'
                    : 'Неверный код текущей почты',
                ok: ok,
              );
              return;
            }

            final email = newEmailCtrl.text.trim();
            if (Validators.email(email) != null) {
              _showMessage('Введите корректную новую почту');
              return;
            }
            setModal(() => loading = true);
            final masked = await auth.requestNewEmailCode(newEmail: email);
            if (!context.mounted) return;
            setModal(() {
              loading = false;
              maskedNew = (masked != null && masked.isNotEmpty) ? masked : null;
              newCodeSent = maskedNew != null;
            });
            _showMessage(
              newCodeSent
                  ? 'Код отправлен на $maskedNew'
                  : 'Не удалось отправить код на новую почту',
              ok: newCodeSent,
            );
          }

          Future<void> confirmNewEmail() async {
            if (newCodeCtrl.text.trim().length != 6) {
              _showMessage('Введите код с новой почты');
              return;
            }
            final email = newEmailCtrl.text.trim();
            if (Validators.email(email) != null) {
              _showMessage('Введите корректную новую почту');
              return;
            }
            setModal(() => loading = true);
            final error = await auth.confirmNewEmail(newCodeCtrl.text.trim(), email);
            final ok = error == null;
            if (!context.mounted) return;
            setModal(() => loading = false);
            if (ok) {
              ref.invalidate(currentProfileProvider);
              Navigator.of(ctx).pop();
            }
            _showMessage(
              ok ? 'Email успешно изменён' : error!,
              ok: ok,
            );
          }

          return _modalFrame(
            context: ctx,
            title: step == 1
                ? 'Верификация безопасности'
                : 'Изменить привязанную электронную почту',
            icon: Icons.mark_email_read_outlined,
            subtitle: step == 1
                ? 'Введите код подтверждения из эл. письма для проверки личности'
                      '${maskedCurrent != null ? '\n$maskedCurrent' : ''}'
                : 'Введите электронную почту, которую вы хотите привязать к учётной записи',
            body: Column(
              children: [
                if (step == 1) ...[
                  _field(ctx, currentCodeCtrl, 'Код подтверждения'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : sendCurrentCode,
                      child: const Text('Отправить'),
                    ),
                  ),
                ] else ...[
                  _field(ctx, newEmailCtrl, 'Электронная почта'),
                  const SizedBox(height: 10),
                  _field(ctx, newCodeCtrl, 'Код подтверждения'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : sendNewCodeAndProceed,
                      child: Text(newCodeSent ? 'Переотправить' : 'Отправить'),
                    ),
                  ),
                  if (maskedNew != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Код отправлен на $maskedNew',
                      style: AppTypography.caption.copyWith(
                        color: ctx.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ],
            ),
            loading: loading,
            primaryText: step == 1 ? 'Далее' : (newCodeSent ? 'ОК' : 'Далее'),
            onPrimary: step == 1
                ? sendNewCodeAndProceed
                : (newCodeSent ? confirmNewEmail : sendNewCodeAndProceed),
          );
        },
      ),
    );
  }

  Future<void> _openDeleteAccountModal() async {
    final auth = ref.read(authServiceProvider);
    final codeCtrl = TextEditingController();
    bool loading = false;
    String? maskedEmail;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> sendCode() async {
            setModal(() => loading = true);
            final masked = await auth.requestDeleteAccountCode();
            if (!context.mounted) return;
            setModal(() {
              loading = false;
              maskedEmail = (masked != null && masked.isNotEmpty)
                  ? masked
                  : null;
            });
            _showMessage(
              maskedEmail != null
                  ? 'Код отправлен на $maskedEmail'
                  : 'Не удалось отправить код удаления',
              ok: maskedEmail != null,
            );
          }

          Future<void> confirmDelete() async {
            if (codeCtrl.text.trim().length != 6) {
              _showMessage('Введите код из письма');
              return;
            }

            setModal(() => loading = true);
            final ok = await auth.deleteAccount(code: codeCtrl.text.trim());
            if (!mounted) return;
            setModal(() => loading = false);

            if (!ok) {
              _showMessage('Не удалось удалить аккаунт (проверьте код)');
              return;
            }

            await ref.read(authStateProvider.notifier).logout();
            if (!mounted) return;
            context.go('/login');
            _showMessage('Аккаунт удалён', ok: true);
          }

          return _modalFrame(
            context: ctx,
            title: 'Удаление аккаунта',
            icon: Icons.delete_forever_outlined,
            subtitle:
                'Подтвердите удаление кодом из email.\n'
                'Если передумаете, просто закройте окно.',
            body: Column(
              children: [
                _field(ctx, codeCtrl, 'Код подтверждения'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : sendCode,
                    child: Text(
                      maskedEmail == null ? 'Отправить код' : 'Переотправить',
                    ),
                  ),
                ),
                if (maskedEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Код отправлен на $maskedEmail',
                    style: AppTypography.caption.copyWith(
                      color: ctx.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            loading: loading,
            primaryText: 'Удалить аккаунт',
            onPrimary: confirmDelete,
          );
        },
      ),
    );
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
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
    );
  }
}
