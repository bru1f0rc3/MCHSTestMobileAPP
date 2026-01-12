import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/core/widgets/custom_card.dart';
import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';
import 'package:mchs_mobile_app/features/admin/data/services/reports_service.dart';

/// Reports Screen for Admin
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OverallStatisticsDto? _overallStats;
  List<TestStatisticsDto> _testStats = [];
  List<UserPerformanceDto> _userPerformance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportsService = ref.read(reportsServiceProvider);

      // Загружаем общую статистику
      final overallResponse = await reportsService.getOverallStatistics();
      if (overallResponse.success && overallResponse.data != null) {
        _overallStats = overallResponse.data;
      }

      // Загружаем статистику по тестам
      final testsResponse = await reportsService.getTestStatistics();
      if (testsResponse.success && testsResponse.data != null) {
        _testStats = testsResponse.data!.items;
      }

      // Загружаем производительность пользователей
      final usersResponse = await reportsService.getUsersPerformance();
      if (usersResponse.success && usersResponse.data != null) {
        _userPerformance = usersResponse.data!.items;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Отчеты и статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Общая'),
            Tab(text: 'По тестам'),
            Tab(text: 'По пользователям'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverallTab(),
                _buildTestsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildOverallTab() {
    if (_overallStats == null) {
      return const Center(child: Text('Нет данных'));
    }

    final stats = _overallStats!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Пользователи',
                  value: stats.totalUsers.toString(),
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Тесты',
                  value: stats.totalTests.toString(),
                  icon: Icons.quiz,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Лекции',
                  value: stats.totalLectures.toString(),
                  icon: Icons.book,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Пройдено',
                  value: stats.totalCompletedTests.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Metrics
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Общая эффективность',
                  style: AppTypography.heading4.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  label: 'Средний балл',
                  value: '${stats.averageScore.toStringAsFixed(1)}%',
                  color: _getScoreColor(stats.averageScore),
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  label: 'Процент сдачи',
                  value: '${stats.overallPassRate.toStringAsFixed(1)}%',
                  color: _getScoreColor(stats.overallPassRate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Popular Tests
          if (stats.popularTests.isNotEmpty) ...[
            Text(
              'Популярные тесты',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.popularTests.map((test) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.testTitle,
                          style: AppTypography.body1.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SmallMetric(
                                label: 'Попыток',
                                value: test.attemptCount.toString(),
                              ),
                            ),
                            Expanded(
                              child: _SmallMetric(
                                label: 'Ср. балл',
                                value: '${test.averageScore.toStringAsFixed(0)}%',
                              ),
                            ),
                            Expanded(
                              child: _SmallMetric(
                                label: 'Сдали',
                                value: '${test.passRate.toStringAsFixed(0)}%',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Recent Activity
          if (stats.recentActivity.isNotEmpty) ...[
            Text(
              'Недавняя активность',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.recentActivity.take(10).map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CustomCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: activity.status == 'passed'
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            activity.status == 'passed'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: activity.status == 'passed'
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.username,
                                style: AppTypography.body1.copyWith(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                activity.testTitle,
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${activity.score.toStringAsFixed(0)}%',
                          style: AppTypography.body1.copyWith(
                            color: _getScoreColor(activity.score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildTestsTab() {
    if (_testStats.isEmpty) {
      return const Center(child: Text('Нет данных по тестам'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _testStats.length,
        itemBuilder: (context, index) {
          final test = _testStats[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.testTitle,
                    style: AppTypography.heading4.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          label: 'Попыток',
                          value: test.totalAttempts.toString(),
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: 'Завершено',
                          value: test.completedAttempts.toString(),
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: 'Сдали',
                          value: test.passedAttempts.toString(),
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: 'Провалили',
                          value: test.failedAttempts.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          label: 'Средний балл',
                          value: '${test.averageScore.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: 'Процент сдачи',
                          value: '${test.passRate.toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_userPerformance.isEmpty) {
      return const Center(child: Text('Нет данных по пользователям'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: AppSpacing.paddingLg,
        itemCount: _userPerformance.length,
        itemBuilder: (context, index) {
          final user = _userPerformance[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            if (user.lastActivity != null)
                              Text(
                                'Последняя активность: ${_formatDate(user.lastActivity!)}',
                                style: AppTypography.caption.copyWith(
                                  color: context.textTertiaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          label: 'Завершено тестов',
                          value: user.testsCompleted.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          label: 'Средний балл',
                          value: '${user.averageScore.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: 'Процент сдачи',
                          value: '${user.passRate.toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
                  if (user.lastActivity != null) ...[
                    const SizedBox(height: 12),
                    _MetricColumn(
                      label: 'Последняя активность',
                      value: _formatDateTime(user.lastActivity!),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'сегодня';
    } else if (diff.inDays == 1) {
      return 'вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: context.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body1.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: AppTypography.heading4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.heading4.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.textTertiaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SmallMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTypography.body1.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.textTertiaryColor,
          ),
        ),
      ],
    );
  }
}
