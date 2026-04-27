import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/providers/test_provider.dart';

class TestsScreen extends ConsumerWidget {
  final int? lectureId;

  const TestsScreen({super.key, this.lectureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testListProvider);
    final filtered = lectureId != null
        ? state.tests.where((t) => t.lectureId == lectureId).toList()
        : state.tests;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(lectureId != null ? 'Тесты по теме' : 'Тесты'),
        leading: lectureId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'История',
            onPressed: () => context.push('/test-history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(testListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(testListProvider.notifier).refresh(),
        child: _body(context, ref, state, filtered),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    TestListState state,
    List<TestModel> filtered,
  ) {
    if (state.isLoading && state.tests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tests.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(testListProvider.notifier).refresh(),
      );
    }

    if (filtered.isEmpty) {
      return EmptyState(
        icon: lectureId != null
            ? Icons.quiz_outlined
            : Icons.check_circle_outline,
        title: lectureId != null
            ? 'По этой теме тестов пока нет'
            : 'Все тесты пройдены',
        message: lectureId == null
            ? 'Повторить тесты можно в истории'
            : null,
        action: lectureId == null
            ? TextButton.icon(
                onPressed: () => context.push('/test-history'),
                icon: const Icon(Icons.history_outlined, size: 18),
                label: const Text('История тестов'),
              )
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: filtered.length + (lectureId == null && state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _TestTile(test: filtered[index]);
      },
    );
  }
}

class _TestTile extends StatelessWidget {
  final TestModel test;
  const _TestTile({required this.test});

  @override
  Widget build(BuildContext context) {
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
                  maxLines: 2,
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
                    if (test.createdAt != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '·',
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatDate(test.createdAt!),
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textTertiaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}
