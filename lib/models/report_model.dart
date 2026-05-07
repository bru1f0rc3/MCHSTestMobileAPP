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
      popularTests:
          (json['popularTests'] as List?)
              ?.map((e) => PopularTestDto.fromJson(e))
              .toList() ??
          [],
      recentActivity:
          (json['recentActivity'] as List?)
              ?.map((e) => UserActivityDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

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

class DetailedReportDto {
  final DateTime generatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? testId;
  final String? testTitle;
  final String kind;

  final int totalResults;
  final int completedResults;
  final int passedResults;
  final int failedResults;
  final int totalCheatAttempts;
  final double averageScore;
  final double passRate;
  final double averageDurationSeconds;
  final List<TestResultSummaryDto> results;

  DetailedReportDto({
    required this.generatedAt,
    this.startDate,
    this.endDate,
    this.testId,
    this.testTitle,
    this.kind = 'all',
    required this.totalResults,
    required this.completedResults,
    this.passedResults = 0,
    this.failedResults = 0,
    this.totalCheatAttempts = 0,
    required this.averageScore,
    required this.passRate,
    this.averageDurationSeconds = 0,
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
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      testId: json['testId'],
      testTitle: json['testTitle'],
      kind: (json['kind'] ?? 'all') as String,
      totalResults: json['totalResults'] ?? 0,
      completedResults: json['completedResults'] ?? 0,
      passedResults: json['passedResults'] ?? 0,
      failedResults: json['failedResults'] ?? 0,
      totalCheatAttempts: json['totalCheatAttempts'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
      averageDurationSeconds: (json['averageDurationSeconds'] ?? 0).toDouble(),
      results:
          (json['results'] as List?)
              ?.map((e) => TestResultSummaryDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TestResultSummaryDto {
  final int id;
  final String username;
  final String? fullName;
  final String? email;
  final String testTitle;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? score;
  final int passingScore;
  final int? timeLimitMinutes;
  final int? durationSeconds;
  final int cheatAttempts;
  final bool autoSubmitted;
  final String status;

  TestResultSummaryDto({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    required this.testTitle,
    required this.startedAt,
    this.finishedAt,
    this.score,
    this.passingScore = 70,
    this.timeLimitMinutes,
    this.durationSeconds,
    this.cheatAttempts = 0,
    this.autoSubmitted = false,
    required this.status,
  });

  factory TestResultSummaryDto.fromJson(Map<String, dynamic> json) {
    return TestResultSummaryDto(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: (json['fullName'] as String?)?.trim().isEmpty == true
          ? null
          : json['fullName'] as String?,
      email: (json['email'] as String?)?.trim().isEmpty == true
          ? null
          : json['email'] as String?,
      testTitle: json['testTitle'] ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      passingScore: (json['passingScore'] ?? 70) as int,
      timeLimitMinutes: json['timeLimitMinutes'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      cheatAttempts: (json['cheatAttempts'] ?? 0) as int,
      autoSubmitted: (json['autoSubmitted'] ?? false) as bool,
      status: json['status'] ?? '',
    );
  }
}
