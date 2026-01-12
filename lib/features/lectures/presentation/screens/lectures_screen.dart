import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/features/lectures/data/models/lecture_model.dart';

class LecturesScreen extends ConsumerWidget {
  const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureState = ref.watch(lectureListProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Лекции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(lectureListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(lectureListProvider.notifier).refresh(),
        child: _buildBody(context, ref, lectureState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LectureListState state,
  ) {
    if (state.isLoading && state.lectures.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.lectures.isEmpty) {
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

    if (state.lectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: context.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Лекции отсутствуют',
              style: AppTypography.heading4.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: state.lectures.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.lectures.length) {
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

        final lecture = state.lectures[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LectureCard(lecture: lecture),
        );
      },
    );
  }
}

class _LectureCard extends StatelessWidget {
  final LectureModel lecture;

  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: () => context.push('/lecture-detail/${lecture.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book,
                  color: context.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.title,
                      style: AppTypography.heading4.copyWith(
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lecture.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(lecture.createdAt!),
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
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
          if (lecture.textContent != null && lecture.textContent!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lecture.textContent!,
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
