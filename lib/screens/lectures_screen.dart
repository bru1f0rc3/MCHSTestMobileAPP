import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/models/lecture_model.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';

class LecturesScreen extends ConsumerWidget {
  const LecturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lectureListProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Лекции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(lectureListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(lectureListProvider.notifier).refresh(),
        child: _buildBody(context, ref, state),
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
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(lectureListProvider.notifier).refresh(),
      );
    }

    if (state.lectures.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Пока нет лекций',
        message: 'Загляните позже — материалы скоро появятся',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: state.lectures.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == state.lectures.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _LectureTile(lecture: state.lectures[index]);
      },
    );
  }
}

class _LectureTile extends StatelessWidget {
  final LectureModel lecture;
  const _LectureTile({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final hasVideo =
        lecture.videoPath != null && lecture.videoPath!.isNotEmpty;
    final hasPdf =
        lecture.documentPath != null && lecture.documentPath!.isNotEmpty;

    return CustomCard(
      onTap: () => context.push('/lecture-detail/${lecture.id}'),
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
              Icons.menu_book_outlined,
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
                  lecture.title,
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasVideo)
                      const _Badge(
                        icon: Icons.play_circle_outline,
                        label: 'Видео',
                      ),
                    if (hasVideo && hasPdf) const SizedBox(width: 6),
                    if (hasPdf)
                      const _Badge(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                      ),
                    if ((hasVideo || hasPdf) && lecture.createdAt != null)
                      const SizedBox(width: 6),
                    if (lecture.createdAt != null)
                      Text(
                        _formatDate(lecture.createdAt!),
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiaryColor,
                        ),
                      ),
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.textSecondaryColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
