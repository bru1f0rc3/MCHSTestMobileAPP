import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';

class TestsScreen extends ConsumerWidget {
  final int? lectureId;
  
  const TestsScreen({super.key, this.lectureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(testListProvider);
    
    // Filter tests by lectureId if provided
    final filteredTests = lectureId != null
        ? testState.tests.where((t) => t.lectureId == lectureId).toList()
        : testState.tests;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(lectureId != null ? 'Тесты по теме' : 'Тесты'),
        leading: lectureId != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/test-history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(testListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(testListProvider.notifier).refresh(),
        child: _buildBody(context, ref, testState, filteredTests),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TestListState state,
    List<TestModel> filteredTests,
  ) {
    if (state.isLoading && state.tests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: AppTypography.heading4.copyWith(color: context.errorColor),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: AppTypography.body2.copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (filteredTests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lectureId != null 
                  ? Icons.quiz_outlined
                  : Icons.check_circle_outline,
              size: 64,
              color: lectureId != null 
                  ? context.textTertiaryColor
                  : AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              lectureId != null 
                  ? 'Тесты по данной теме отсутствуют'
                  : 'Все тесты пройдены!',
              style: AppTypography.heading4.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (lectureId == null) ...[
              const SizedBox(height: 8),
              Text(
                'Вы можете перепройти тесты в истории',
                style: AppTypography.body2.copyWith(
                  color: context.textTertiaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.push('/test-history'),
                icon: const Icon(Icons.history),
                label: const Text('История тестов'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: filteredTests.length + (lectureId == null && state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredTests.length) {
          if (state.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final test = filteredTests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TestCard(test: test),
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;

  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: () => context.push('/test-detail/${test.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: AppTypography.heading4.copyWith(
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (test.description != null && test.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        test.description!,
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.textTertiaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.help_outline,
                label: '${test.questionCount ?? 0} вопросов',
              ),
              const SizedBox(width: 8),
              if (test.createdAt != null)
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(test.createdAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.textSecondaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
