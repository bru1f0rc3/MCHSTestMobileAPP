import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';
import 'package:mchs_mobile_app/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/utils/validators.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/services/user_service.dart';

final usersProvider = FutureProvider.autoDispose<List<UserDto>>((ref) async {
  ref.watch(usersVersionProvider);
  final service = ref.watch(userServiceProvider);
  final response = await service.getAll(pageSize: 100);
  return response.data?.items ?? [];
});
final rolesProvider = FutureProvider.autoDispose<List<RoleDto>>((ref) async {
  final service = ref.watch(userServiceProvider);
  final response = await service.getRoles();
  return response.data ?? [];
});
void refreshAllUserProviders(WidgetRef ref) {
  ref.read(refreshProvider.notifier).refresh(RefreshType.users);
  ref.invalidate(usersProvider);
}

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  bool _isProcessing = false;

  void _refresh() => refreshAllUserProviders(ref);

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            title: const Text('Пользователи'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refresh,
                tooltip: 'Обновить',
              ),
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: _showCreateUserDialog,
                tooltip: 'Добавить',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени или роли',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: context.textTertiaryColor,
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              Expanded(
                child: usersAsync.when(
                  data: (users) => _buildUsersList(users),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(
                    message: ErrorHandler.getErrorMessage(error),
                    onRetry: _refresh,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildUsersList(List<UserDto> users) {
    final filteredUsers = users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) ||
          user.role.toLowerCase().contains(_searchQuery) ||
          _getRoleName(user.role).toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _searchQuery.isEmpty
            ? 'Пользователей пока нет'
            : 'Ничего не найдено',
        message: _searchQuery.isEmpty
            ? 'Добавьте первого пользователя'
            : null,
      );
    }

    final authState = ref.watch(authStateProvider);
    final isSuperAdmin = authState.isSuperAdmin;
    final currentUserId = authState.user?.id;

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final roleLower = user.role.toLowerCase();
          final isSelf = currentUserId != null && user.id == currentUserId;
          final canManage = !isSelf &&
              (isSuperAdmin ||
                  (roleLower != 'admin' && roleLower != 'superadmin'));
          return _UserCard(
            user: user,
            canManage: canManage,
            isSelf: isSelf,
            onEdit: () => _showEditUserDialog(user),
            onDelete: () => _confirmDeleteUser(user),
          );
        },
      ),
    );
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    int? selectedRoleId;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final rolesAsync = ref.watch(rolesProvider);

          return AlertDialog(
            title: const Text('Создать пользователя'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: usernameController,
                      label: 'Имя пользователя',
                      hint: 'Введите имя',
                      prefixIcon: Icons.person,
                      validator: Validators.username,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Пароль',
                      hint: 'Введите пароль',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      data: (roles) {
                        final isSuperAdmin = ref
                            .watch(authStateProvider)
                            .isSuperAdmin;
                        final visibleRoles = roles
                            .where(
                              (r) =>
                                  isSuperAdmin ||
                                  (r.name.toLowerCase() != 'admin' &&
                                      r.name.toLowerCase() != 'superadmin'),
                            )
                            .toList();
                        if (visibleRoles.isEmpty) {
                          return const Text('Нет доступных ролей');
                        }
                        if (selectedRoleId == null ||
                            !visibleRoles.any(
                              (r) => r.id == selectedRoleId,
                            )) {
                          final defaultRole = visibleRoles.firstWhere(
                            (r) => r.name.toLowerCase() == 'user',
                            orElse: () => visibleRoles.first,
                          );
                          selectedRoleId = defaultRole.id;
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: selectedRoleId,
                          decoration: const InputDecoration(
                            labelText: 'Роль',
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: visibleRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role.id,
                                  child: Text(_getRoleName(role.name)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) selectedRoleId = value;
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Ошибка загрузки ролей'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => _createUser(
                  dialogContext,
                  formKey,
                  usernameController,
                  passwordController,
                  selectedRoleId,
                ),
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createUser(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    TextEditingController usernameController,
    TextEditingController passwordController,
    int? roleId,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (roleId == null) {
      ErrorHandler.showErrorSnackBar(
        dialogContext,
        'Выберите роль для пользователя',
      );
      return;
    }

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(userServiceProvider);
      await service.create(
        CreateUserRequest(
          username: usernameController.text.trim(),
          password: passwordController.text,
          roleId: roleId,
        ),
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Пользователь успешно создан',
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showEditUserDialog(UserDto user) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user.username);
    int? selectedRoleId;

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final rolesAsync = ref.watch(rolesProvider);

          return AlertDialog(
            title: const Text('Редактировать пользователя'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: usernameController,
                      label: 'Имя пользователя',
                      hint: 'Введите имя',
                      prefixIcon: Icons.person,
                      validator: Validators.username,
                    ),
                    const SizedBox(height: 16),
                    rolesAsync.when(
                      data: (roles) {
                        final isSuperAdmin = ref
                            .watch(authStateProvider)
                            .isSuperAdmin;
                        final visibleRoles = roles
                            .where(
                              (r) =>
                                  isSuperAdmin ||
                                  (r.name.toLowerCase() != 'admin' &&
                                      r.name.toLowerCase() != 'superadmin'),
                            )
                            .toList();
                        if (visibleRoles.isEmpty) {
                          return const Text('Нет доступных ролей');
                        }
                        if (selectedRoleId == null ||
                            !visibleRoles.any(
                              (r) => r.id == selectedRoleId,
                            )) {
                          final currentRole = visibleRoles.firstWhere(
                            (r) =>
                                r.name.toLowerCase() ==
                                user.role.toLowerCase(),
                            orElse: () => visibleRoles.first,
                          );
                          selectedRoleId = currentRole.id;
                        }
                        return DropdownButtonFormField<int>(
                          initialValue: selectedRoleId,
                          decoration: const InputDecoration(
                            labelText: 'Роль',
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: visibleRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role.id,
                                  child: Text(_getRoleName(role.name)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) selectedRoleId = value;
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Ошибка загрузки ролей'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => _updateUser(
                  dialogContext,
                  formKey,
                  user,
                  usernameController,
                  selectedRoleId,
                ),
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateUser(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    UserDto user,
    TextEditingController usernameController,
    int? roleId,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(userServiceProvider);
      await service.update(
        user.id,
        UpdateUserRequest(
          username: usernameController.text.trim() != user.username
              ? usernameController.text.trim()
              : null,
          roleId: roleId,
        ),
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Пользователь успешно обновлен',
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmDeleteUser(UserDto user) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: 'Удалить пользователя?',
      message:
          'Вы уверены, что хотите удалить пользователя "${user.username}"?\n\nЭто действие нельзя отменить.',
      confirmText: 'Удалить',
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = ref.read(userServiceProvider);
      await service.delete(user.id);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Пользователь успешно удален',
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Суперадминистратор';
      case 'admin':
        return 'Администратор';
      case 'user':
        return 'Пользователь';
      case 'guest':
        return 'Гость';
      default:
        return role;
    }
  }
}

class _UserCard extends StatelessWidget {
  final UserDto user;
  final bool canManage;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.canManage,
    required this.isSelf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);
    return CustomCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(_getRoleIcon(user.role), color: roleColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        style: AppTypography.body1.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'вы',
                          style: AppTypography.caption.copyWith(
                            color: context.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _getRoleName(user.role),
                      style: AppTypography.caption.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiaryColor,
                      ),
                    ),
                    Text(
                      _formatDate(user.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: context.textTertiaryColor,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Удалить',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Icon(
              Icons.lock_outline,
              size: 18,
              color: context.textTertiaryColor,
            ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return AppColors.error;
      case 'admin':
        return AppColors.accent;
      case 'user':
        return AppColors.primary;
      case 'guest':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Icons.verified_user;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'user':
        return Icons.person;
      case 'guest':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Суперадминистратор';
      case 'admin':
        return 'Администратор';
      case 'user':
        return 'Пользователь';
      case 'guest':
        return 'Гость';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
