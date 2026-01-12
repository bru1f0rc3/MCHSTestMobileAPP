import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/providers/refresh_provider.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/utils/validators.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/core/widgets/custom_text_field.dart';
import 'package:mchs_mobile_app/features/admin/data/services/user_service.dart';

/// Users Provider with version-based refresh
final usersProvider = FutureProvider.autoDispose<List<UserDto>>((ref) async {
  ref.watch(usersVersionProvider);
  final service = ref.watch(userServiceProvider);
  final response = await service.getAll(pageSize: 100);
  return response.data?.items ?? [];
});

/// Roles Provider
final rolesProvider = FutureProvider.autoDispose<List<RoleDto>>((ref) async {
  final service = ref.watch(userServiceProvider);
  final response = await service.getRoles();
  return response.data ?? [];
});

/// Helper function to refresh all user-related providers
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
            title: const Text('Управление пользователями'),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh, tooltip: 'Обновить'),
              IconButton(icon: const Icon(Icons.person_add), onPressed: _showCreateUserDialog, tooltip: 'Добавить пользователя'),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: AppSpacing.paddingMd,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск пользователей...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              Expanded(
                child: usersAsync.when(
                  data: (users) => _buildUsersList(users),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _buildErrorState(error),
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

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Ошибка загрузки', style: AppTypography.heading4.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(ErrorHandler.getErrorMessage(error), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          CustomButton(text: 'Повторить', onPressed: _refresh),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserDto> users) {
    final filteredUsers = users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) || user.role.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: context.textTertiaryColor),
            const SizedBox(height: 24),
            Text(_searchQuery.isEmpty ? 'Нет пользователей' : 'Ничего не найдено', style: AppTypography.heading4.copyWith(color: context.textPrimaryColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: AppSpacing.paddingMd,
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return _UserCard(
            user: user,
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
    int selectedRoleId = 2;

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
                        return DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: const InputDecoration(labelText: 'Роль', prefixIcon: Icon(Icons.admin_panel_settings)),
                          items: roles.map((role) => DropdownMenuItem(value: role.id, child: Text(_getRoleName(role.name)))).toList(),
                          onChanged: (value) => selectedRoleId = value ?? 2,
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
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
              TextButton(
                onPressed: () => _createUser(dialogContext, formKey, usernameController, passwordController, selectedRoleId),
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createUser(BuildContext dialogContext, GlobalKey<FormState> formKey, TextEditingController usernameController, TextEditingController passwordController, int roleId) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(userServiceProvider);
      await service.create(CreateUserRequest(username: usernameController.text.trim(), password: passwordController.text, roleId: roleId));
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Пользователь успешно создан');
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
                        final currentRole = roles.firstWhere((r) => r.name.toLowerCase() == user.role.toLowerCase(), orElse: () => roles.first);
                        selectedRoleId ??= currentRole.id;
                        return DropdownButtonFormField<int>(
                          value: selectedRoleId,
                          decoration: const InputDecoration(labelText: 'Роль', prefixIcon: Icon(Icons.admin_panel_settings)),
                          items: roles.map((role) => DropdownMenuItem(value: role.id, child: Text(_getRoleName(role.name)))).toList(),
                          onChanged: (value) => selectedRoleId = value,
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
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
              TextButton(
                onPressed: () => _updateUser(dialogContext, formKey, user, usernameController, selectedRoleId),
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateUser(BuildContext dialogContext, GlobalKey<FormState> formKey, UserDto user, TextEditingController usernameController, int? roleId) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final service = ref.read(userServiceProvider);
      await service.update(user.id, UpdateUserRequest(
        username: usernameController.text.trim() != user.username ? usernameController.text.trim() : null,
        roleId: roleId,
      ));
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Пользователь успешно обновлен');
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
      message: 'Вы уверены, что хотите удалить пользователя "${user.username}"?\n\nЭто действие нельзя отменить.',
      confirmText: 'Удалить',
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final service = ref.read(userServiceProvider);
      await service.delete(user.id);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Пользователь успешно удален');
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getRoleIcon(user.role),
                color: _getRoleColor(user.role),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: AppTypography.body1.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRoleName(user.role),
                          style: AppTypography.caption.copyWith(
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
            PopupMenuButton<String>(
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
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Удалить', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
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
