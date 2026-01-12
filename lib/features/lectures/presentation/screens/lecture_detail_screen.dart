import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_button.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/lectures/providers/lecture_provider.dart';
import 'package:mchs_mobile_app/features/lectures/presentation/widgets/pdf_viewer_widget.dart';
import 'package:mchs_mobile_app/features/lectures/presentation/widgets/video_player_widget.dart';

class LectureDetailScreen extends ConsumerWidget {
  final int lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureAsync = ref.watch(lectureDetailProvider(lectureId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Лекция'),
      ),
      body: lectureAsync.when(
        data: (lecture) {
          if (lecture == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Лекция не найдена',
                    style: AppTypography.heading4.copyWith(
                      color: context.errorColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                CustomCard(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.book,
                          color: context.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lecture.title,
                              style: AppTypography.heading3.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (lecture.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Добавлено: ${_formatDate(lecture.createdAt!)}',
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Video Player (if available)
                if (lecture.videoPath != null && lecture.videoPath!.isNotEmpty) ...[
                  Text(
                    'Видеоматериал',
                    style: AppTypography.heading4.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerWidget(
                            videoUrl: lecture.videoPath!,
                            title: lecture.title,
                            autoPlay: true,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.play_circle_filled,
                            color: context.primaryColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Смотреть видео',
                                style: AppTypography.body1.copyWith(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Нажмите для воспроизведения',
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.textTertiaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // PDF Document (if available)
                if (lecture.documentPath != null && lecture.documentPath!.isNotEmpty) ...[
                  Text(
                    'Документ',
                    style: AppTypography.heading4.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerWidget(
                            pdfUrl: lecture.documentPath!,
                            title: lecture.title,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: context.errorColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Открыть PDF',
                                style: AppTypography.body1.copyWith(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Нажмите для просмотра',
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.textTertiaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content
                if (lecture.textContent != null &&
                    lecture.textContent!.isNotEmpty) ...[
                  Text(
                    'Текстовое содержание',
                    style: AppTypography.heading4.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    child: Text(
                      lecture.textContent!,
                      style: AppTypography.body1.copyWith(
                        color: context.textPrimaryColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                CustomButton(
                  text: 'Перейти к тестам по теме',
                  icon: Icons.quiz,
                  onPressed: () {
                    context.push('/lecture-tests/$lectureId');
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                error.toString(),
                style: AppTypography.body2.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
