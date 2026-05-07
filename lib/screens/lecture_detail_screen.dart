import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/widgets/custom_button.dart';
import 'package:mchs_mobile_app/widgets/custom_card.dart';
import 'package:mchs_mobile_app/widgets/pdf_viewer_widget.dart';
import 'package:mchs_mobile_app/widgets/video_player_widget.dart';
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
          final hasPdf = lecture.documentPath != null &&
              lecture.documentPath!.isNotEmpty;
          final hasText = lecture.textContent != null &&
              lecture.textContent!.isNotEmpty;

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
              if (lecture.createdAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Добавлено ${_formatDate(lecture.createdAt!)}',
                  style: AppTypography.body2.copyWith(
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (hasVideo) ...[
                _ResourceTile(
                  icon: Icons.play_circle_outline,
                  title: 'Видеоматериал',
                  subtitle: 'Смотреть видео',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerWidget(
                          videoUrl: lecture.videoPath!,
                          title: lecture.title,
                          autoPlay: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (hasPdf) ...[
                _ResourceTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Документ PDF',
                  subtitle: 'Открыть документ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerWidget(
                          pdfUrl: lecture.documentPath!,
                          title: lecture.title,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (hasText) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Содержание',
                  style: AppTypography.heading4.copyWith(
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomCard(
                  child: Text(
                    lecture.textContent!,
                    style: AppTypography.body1.copyWith(
                      color: context.textPrimaryColor,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                text: 'Перейти к тестам',
                icon: Icons.quiz_outlined,
                onPressed: () => context.push('/lecture-tests/$lectureId'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(message: error.toString()),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
                  style: AppTypography.body2.copyWith(
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
