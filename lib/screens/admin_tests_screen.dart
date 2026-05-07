import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/utils/error_handler.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/services/test_service.dart';
import 'package:mchs_mobile_app/providers/test_provider.dart';

class AdminTestsScreen extends ConsumerStatefulWidget {
  const AdminTestsScreen({super.key});

  @override
  ConsumerState<AdminTestsScreen> createState() => _AdminTestsScreenState();
}

class _AdminTestsScreenState extends ConsumerState<AdminTestsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final testsState = ref.watch(allTestListProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Тесты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Обновить',
            onPressed: () => _refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Импорт из PDF',
            onPressed: () => _navigateToImport(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Создать тест',
            onPressed: () => _navigateToCreate(),
          ),
        ],
      ),
      body: _buildBody(testsState),
    );
  }

  Future<void> _refresh() async {
    await ref.read(allTestListProvider.notifier).refresh();
  }

  void _navigateToCreate() {
    context.push('/admin/create-test').then((result) {
      if (result == true) {
        refreshAllTestProviders(ref);
      }
    });
  }

  void _navigateToImport() {
    context.push('/admin/import-test').then((result) {
      if (result == true) {
        refreshAllTestProviders(ref);
      }
    });
  }

  Widget _buildBody(TestListState testsState) {
    if (testsState.isLoading && testsState.tests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (testsState.error != null && testsState.tests.isEmpty) {
      return _buildErrorState(testsState.error!);
    }

    final tests = testsState.tests;
    if (tests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _buildTestCard(tests[index]),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorState(
      message: ErrorHandler.getErrorMessage(error),
      onRetry: _refresh,
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.quiz_outlined,
      title: 'Нет тестов',
      message: 'Создайте новый тест или импортируйте из PDF',
      action: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _navigateToCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Создать'),
          ),
          OutlinedButton.icon(
            onPressed: _navigateToImport,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Импорт PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(test) {
    return CustomCard(
      onTap: () => context.push('/test-detail/${test.id}'),
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
              color: context.primaryColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: context.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (test.description != null &&
                    test.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    test.description!,
                    style: AppTypography.body2.copyWith(
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 12,
                      color: context.textTertiaryColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${test.questionCount ?? 0} вопросов',
                      style: AppTypography.caption.copyWith(
                        color: context.textTertiaryColor,
                      ),
                    ),
                    if (test.lectureTitle != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '·',
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          test.lectureTitle!,
                          style: AppTypography.caption.copyWith(
                            color: context.textTertiaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isDeleting,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: context.textTertiaryColor,
            ),
            onSelected: (value) => _handleMenuAction(value, test),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Просмотр'),
                  ],
                ),
              ),
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
              const PopupMenuDivider(),
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
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, test) {
    switch (action) {
      case 'view':
        context.push('/test-detail/${test.id}');
        break;
      case 'edit':
        context.push('/admin/edit-test/${test.id}').then((result) {
          if (result == true) {
            refreshAllTestProviders(ref);
          }
        });
        break;
      case 'delete':
        _confirmDelete(test.id, test.title);
        break;
    }
  }

  Future<void> _confirmDelete(int testId, String title) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: 'Удалить тест?',
      message:
          'Вы уверены, что хотите удалить тест "$title"?\n\nЭто действие нельзя отменить.',
      confirmText: 'Удалить',
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final testService = ref.read(testServiceProvider);
      final result = await testService.delete(testId);
      if (!mounted) return;

      if (result.success) {
        ErrorHandler.showSuccessSnackBar(context, 'Тест успешно удален');
        refreshAllTestProviders(ref);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          result.message ?? 'Не удалось удалить тест',
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
