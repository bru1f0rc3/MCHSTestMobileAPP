import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/utils/error_handler.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/data/services/test_service.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

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
        title: const Text('Управление тестами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => _refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать тест',
            onPressed: () => _navigateToCreate(),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Импорт из PDF',
            onPressed: () => _navigateToImport(),
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
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildTestCard(test),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: AppTypography.heading4.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              ErrorHandler.getErrorMessage(error),
              style: AppTypography.body2.copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Повторить', icon: Icons.refresh, onPressed: _refresh),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: context.textTertiaryColor),
            const SizedBox(height: 24),
            Text('Нет тестов', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Создайте новый тест или импортируйте из PDF', style: AppTypography.body2.copyWith(color: context.textSecondaryColor), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                CustomButton(text: 'Создать тест', icon: Icons.add, onPressed: _navigateToCreate),
                CustomButton(text: 'Импорт PDF', icon: Icons.upload_file, isOutlined: true, onPressed: _navigateToImport),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(test) {
    return CustomCard(
      onTap: () => context.push('/test-detail/${test.id}'),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.quiz, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.title, style: AppTypography.body1.copyWith(color: context.textPrimaryColor, fontWeight: FontWeight.w600)),
                if (test.description != null && test.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(test.description!, style: AppTypography.caption.copyWith(color: context.textTertiaryColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: context.textTertiaryColor),
                    const SizedBox(width: 4),
                    Text('${test.questionCount ?? 0} вопросов', style: AppTypography.caption.copyWith(color: context.textTertiaryColor)),
                    if (test.lectureTitle != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.book_outlined, size: 16, color: context.textTertiaryColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text(test.lectureTitle!, style: AppTypography.caption.copyWith(color: context.textTertiaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !_isDeleting,
            onSelected: (value) => _handleMenuAction(value, test),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 12), Text('Просмотр')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Редактировать')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.error), SizedBox(width: 12), Text('Удалить', style: TextStyle(color: AppColors.error))])),
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
        ErrorHandler.showWarningSnackBar(context, 'Редактирование тестов будет доступно в следующем обновлении');
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
      message: 'Вы уверены, что хотите удалить тест "$title"?\n\nЭто действие нельзя отменить.',
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
        ErrorHandler.showErrorSnackBar(context, result.message ?? 'Не удалось удалить тест');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}
