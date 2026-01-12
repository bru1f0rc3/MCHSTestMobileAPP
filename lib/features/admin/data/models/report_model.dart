/// User Statistics DTO
class UserStatisticsDto {
  final int userId;
  final String username;
  final int totalTestsTaken;
  final int testsCompleted;
  final int testsPassed;
  final int testsFailed;
  final double averageScore;
  final double passRate;

  UserStatisticsDto({
    required this.userId,
    required this.username,
    required this.totalTestsTaken,
    required this.testsCompleted,
    required this.testsPassed,
    required this.testsFailed,
    required this.averageScore,
    required this.passRate,
  });

  factory UserStatisticsDto.fromJson(Map<String, dynamic> json) {
    return UserStatisticsDto(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      totalTestsTaken: json['totalTestsTaken'] ?? 0,
      testsCompleted: json['testsCompleted'] ?? 0,
      testsPassed: json['testsPassed'] ?? 0,
      testsFailed: json['testsFailed'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
    );
  }
}

/// Overall Statistics DTO
class OverallStatisticsDto {
  final int totalUsers;
  final int totalTests;
  final int totalLectures;
  final int totalTestResults;
  final int totalCompletedTests;
  final double averageScore;
  final double overallPassRate;
  final List<PopularTestDto> popularTests;
  final List<UserActivityDto> recentActivity;

  OverallStatisticsDto({
    required this.totalUsers,
    required this.totalTests,
    required this.totalLectures,
    required this.totalTestResults,
    required this.totalCompletedTests,
    required this.averageScore,
    required this.overallPassRate,
    required this.popularTests,
    required this.recentActivity,
  });

  factory OverallStatisticsDto.fromJson(Map<String, dynamic> json) {
    return OverallStatisticsDto(
      totalUsers: json['totalUsers'] ?? 0,
      totalTests: json['totalTests'] ?? 0,
      totalLectures: json['totalLectures'] ?? 0,
      totalTestResults: json['totalTestResults'] ?? 0,
      totalCompletedTests: json['totalCompletedTests'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      overallPassRate: (json['overallPassRate'] ?? 0).toDouble(),
      popularTests: (json['popularTests'] as List?)
              ?.map((e) => PopularTestDto.fromJson(e))
              .toList() ??
          [],
      recentActivity: (json['recentActivity'] as List?)
              ?.map((e) => UserActivityDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Popular Test DTO
class PopularTestDto {
  final int testId;
  final String testTitle;
  final int attemptCount;
  final double averageScore;
  final double passRate;

  PopularTestDto({
    required this.testId,
    required this.testTitle,
    required this.attemptCount,
    required this.averageScore,
    required this.passRate,
  });

  factory PopularTestDto.fromJson(Map<String, dynamic> json) {
    return PopularTestDto(
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      attemptCount: json['attemptCount'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
    );
  }
}

/// User Activity DTO
class UserActivityDto {
  final String username;
  final String testTitle;
  final DateTime completedAt;
  final double score;
  final String status;

  UserActivityDto({
    required this.username,
    required this.testTitle,
    required this.completedAt,
    required this.score,
    required this.status,
  });

  factory UserActivityDto.fromJson(Map<String, dynamic> json) {
    return UserActivityDto(
      username: json['username'] ?? '',
      testTitle: json['testTitle'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      score: (json['score'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

/// Test Statistics DTO
class TestStatisticsDto {
  final int testId;
  final String testTitle;
  final int totalAttempts;
  final int completedAttempts;
  final int passedAttempts;
  final int failedAttempts;
  final double averageScore;
  final double passRate;

  TestStatisticsDto({
    required this.testId,
    required this.testTitle,
    required this.totalAttempts,
    required this.completedAttempts,
    required this.passedAttempts,
    required this.failedAttempts,
    required this.averageScore,
    required this.passRate,
  });

  factory TestStatisticsDto.fromJson(Map<String, dynamic> json) {
    return TestStatisticsDto(
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      totalAttempts: json['totalAttempts'] ?? 0,
      completedAttempts: json['completedAttempts'] ?? 0,
      passedAttempts: json['passedAttempts'] ?? 0,
      failedAttempts: json['failedAttempts'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
    );
  }
}

/// User Performance DTO
class UserPerformanceDto {
  final int userId;
  final String username;
  final int testsCompleted;
  final double averageScore;
  final double passRate;
  final DateTime? lastActivity;

  UserPerformanceDto({
    required this.userId,
    required this.username,
    required this.testsCompleted,
    required this.averageScore,
    required this.passRate,
    this.lastActivity,
  });

  factory UserPerformanceDto.fromJson(Map<String, dynamic> json) {
    return UserPerformanceDto(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      testsCompleted: json['testsCompleted'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
    );
  }
}

/// Detailed Report DTO
class DetailedReportDto {
  final DateTime generatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalResults;
  final int completedResults;
  final double averageScore;
  final double passRate;
  final List<TestResultSummaryDto> results;

  DetailedReportDto({
    required this.generatedAt,
    this.startDate,
    this.endDate,
    required this.totalResults,
    required this.completedResults,
    required this.averageScore,
    required this.passRate,
    required this.results,
  });

  factory DetailedReportDto.fromJson(Map<String, dynamic> json) {
    return DetailedReportDto(
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      totalResults: json['totalResults'] ?? 0,
      completedResults: json['completedResults'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
      results: (json['results'] as List?)
              ?.map((e) => TestResultSummaryDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Test Result Summary DTO
class TestResultSummaryDto {
  final int id;
  final String username;
  final String testTitle;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? score;
  final String status;

  TestResultSummaryDto({
    required this.id,
    required this.username,
    required this.testTitle,
    required this.startedAt,
    this.finishedAt,
    this.score,
    required this.status,
  });

  factory TestResultSummaryDto.fromJson(Map<String, dynamic> json) {
    return TestResultSummaryDto(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      testTitle: json['testTitle'] ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      status: json['status'] ?? '',
    );
  }
}
