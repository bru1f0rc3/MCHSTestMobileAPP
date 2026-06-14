import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/local_video_player_widget.dart';
import 'package:mchs_mobile_app/widgets/pdf_viewer_widget.dart';
import 'package:mchs_mobile_app/services/storage_service.dart';
import 'package:mchs_mobile_app/providers/lecture_provider.dart';

class LectureDetailScreen extends ConsumerWidget {
  final int lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureAsync = ref.watch(lectureDetailProvider(lectureId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: const Text('Лекция')),
      body: lectureAsync.when(
        data: (lecture) {
          if (lecture == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Лекция не найдена',
            );
          }

          final hasVideo =
              lecture.videoPath != null && lecture.videoPath!.isNotEmpty;
          final hasPdf =
              lecture.documentPath != null &&
              lecture.documentPath!.isNotEmpty;
          final hasText =
              lecture.textContent != null && lecture.textContent!.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                lecture.title,
                style: AppTypography.heading2.copyWith(
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Видео грузится сразу — встроенным нативным плеером.
              if (hasVideo) ...[
                ClipRRect(
                  borderRadius: AppRadius.borderRadiusMd,
                  child: LocalVideoPlayer(source: lecture.videoPath!),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Текст лекции.
              if (hasText) ...[
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    lecture.textContent!,
                    style: AppTypography.body1.copyWith(
                      color: context.textPrimaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Документ PDF.
              if (hasPdf)
                _ResourceTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Документ PDF',
                  subtitle: 'Открыть документ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerWidget(
                          pdfUrl: StorageUrls.fileUrl(lecture.documentPath!),
                          title: lecture.title,
                        ),
                      ),
                    );
                  },
                ),

              if (!hasVideo && !hasPdf && !hasText)
                const EmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'В этой лекции пока нет материалов',
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Ошибка загрузки',
          message: error.toString(),
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
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
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textTertiaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
