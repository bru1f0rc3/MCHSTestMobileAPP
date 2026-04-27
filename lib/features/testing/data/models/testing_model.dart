class StartTestResponse {
  final int testResultId;
  final int testId;
  final String testTitle;
  final DateTime startedAt;
  final int? timeLimitMinutes;
  final DateTime? deadlineAt;
  final int passingScore;
  final List<TestQuestionDto> questions;

  StartTestResponse({
    required this.testResultId,
    required this.testId,
    required this.testTitle,
    required this.startedAt,
    this.timeLimitMinutes,
    this.deadlineAt,
    this.passingScore = 70,
    required this.questions,
  });

  factory StartTestResponse.fromJson(Map<String, dynamic> json) {
    return StartTestResponse(
      testResultId: json['testResultId'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      timeLimitMinutes: json['timeLimitMinutes'],
      deadlineAt: json['deadlineAt'] != null
          ? DateTime.parse(json['deadlineAt'])
          : null,
      passingScore: json['passingScore'] ?? 70,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => TestQuestionDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  int get questionsCount => questions.length;
}

class TestQuestionDto {
  final int questionId;
  final String questionText;
  final int position;
  final List<TestAnswerDto> answers;

  TestQuestionDto({
    required this.questionId,
    required this.questionText,
    required this.position,
    required this.answers,
  });

  factory TestQuestionDto.fromJson(Map<String, dynamic> json) {
    return TestQuestionDto(
      questionId: json['questionId'] ?? 0,
      questionText: json['questionText'] ?? '',
      position: json['position'] ?? 0,
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => TestAnswerDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TestAnswerDto {
  final int answerId;
  final String answerText;
  final int position;

  TestAnswerDto({
    required this.answerId,
    required this.answerText,
    required this.position,
  });

  factory TestAnswerDto.fromJson(Map<String, dynamic> json) {
    return TestAnswerDto(
      answerId: json['answerId'] ?? 0,
      answerText: json['answerText'] ?? '',
      position: json['position'] ?? 0,
    );
  }
}

class SubmitAnswerRequest {
  final int questionId;
  final int answerId;

  SubmitAnswerRequest({required this.questionId, required this.answerId});

  Map<String, dynamic> toJson() {
    return {'questionId': questionId, 'answerId': answerId};
  }
}

class SubmitAnswersRequest {
  final List<SubmitAnswerRequest> answers;

  SubmitAnswersRequest({required this.answers});

  Map<String, dynamic> toJson() {
    return {'answers': answers.map((a) => a.toJson()).toList()};
  }
}

class ReportCheatAttemptRequest {
  final String eventType;
  final String? details;

  ReportCheatAttemptRequest({this.eventType = 'app_background', this.details});

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    if (details != null) 'details': details,
  };
}

class FinishTestResponse {
  final int testResultId;
  final String testTitle;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double score;
  final int passingScore;
  final String status;
  final int totalQuestions;
  final int correctAnswers;
  final int cheatAttempts;
  final bool autoSubmitted;
  final List<QuestionResultDto>? questionResults;

  FinishTestResponse({
    required this.testResultId,
    required this.testTitle,
    required this.startedAt,
    required this.finishedAt,
    required this.score,
    this.passingScore = 70,
    required this.status,
    required this.totalQuestions,
    required this.correctAnswers,
    this.cheatAttempts = 0,
    this.autoSubmitted = false,
    this.questionResults,
  });

  factory FinishTestResponse.fromJson(Map<String, dynamic> json) {
    return FinishTestResponse(
      testResultId: json['testResultId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : DateTime.now(),
      score: (json['score'] ?? 0).toDouble(),
      passingScore: json['passingScore'] ?? 70,
      status: json['status'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      cheatAttempts: json['cheatAttempts'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((e) => QuestionResultDto.fromJson(e))
          .toList(),
    );
  }

  bool get isPassed => status.toLowerCase() == 'passed';
  Duration get duration => finishedAt.difference(startedAt);
}

class QuestionResultDto {
  final int questionId;
  final String questionText;
  final String? userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuestionResultDto({
    required this.questionId,
    required this.questionText,
    this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  factory QuestionResultDto.fromJson(Map<String, dynamic> json) {
    return QuestionResultDto(
      questionId: json['questionId'] ?? 0,
      questionText: json['questionText'] ?? '',
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class TestResultDto {
  final int id;
  final int testId;
  final String testTitle;
  final String? lectureTitle;
  final String? username;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? score;
  final int passingScore;
  final int cheatAttempts;
  final bool autoSubmitted;
  final String status;
  final int totalQuestions;
  final int correctAnswers;

  TestResultDto({
    required this.id,
    required this.testId,
    required this.testTitle,
    this.lectureTitle,
    this.username,
    required this.startedAt,
    this.finishedAt,
    this.score,
    this.passingScore = 70,
    this.cheatAttempts = 0,
    this.autoSubmitted = false,
    required this.status,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
  });

  factory TestResultDto.fromJson(Map<String, dynamic> json) {
    return TestResultDto(
      id: json['id'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      lectureTitle: json['lectureTitle'],
      username: json['username'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score']?.toDouble(),
      passingScore: json['passingScore'] ?? 70,
      cheatAttempts: json['cheatAttempts'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      status: json['status'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
    );
  }

  double get scorePercentage => score ?? 0.0;
  bool get isFinished => finishedAt != null;
  bool get isPassed => status.toLowerCase() == 'passed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
}

class TestResultDetailDto extends TestResultDto {
  final List<QuestionResultDto> questionResults;

  TestResultDetailDto({
    required super.id,
    required super.testId,
    required super.testTitle,
    super.lectureTitle,
    super.username,
    required super.startedAt,
    super.finishedAt,
    super.score,
    super.passingScore = 70,
    super.cheatAttempts = 0,
    super.autoSubmitted = false,
    required super.status,
    required this.questionResults,
  });

  factory TestResultDetailDto.fromJson(Map<String, dynamic> json) {
    return TestResultDetailDto(
      id: json['id'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      lectureTitle: json['lectureTitle'],
      username: json['username'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score']?.toDouble(),
      passingScore: json['passingScore'] ?? 70,
      cheatAttempts: json['cheatAttempts'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      status: json['status'] ?? '',
      questionResults:
          (json['questionResults'] as List<dynamic>?)
              ?.map((e) => QuestionResultDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  int get totalQuestions => questionResults.length;
  @override
  int get correctAnswers => questionResults.where((q) => q.isCorrect).length;
}

class TestResultModel {
  final int id;
  final int testId;
  final String? testTitle;
  final double scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime? finishedAt;
  final bool isPassed;

  TestResultModel({
    required this.id,
    required this.testId,
    this.testTitle,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    this.finishedAt,
    required this.isPassed,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] ?? json['scorePercentage'] ?? 0.0).toDouble();
    final passing = (json['passingScore'] ?? 70).toInt();
    return TestResultModel(
      id: json['id'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'],
      scorePercentage: score,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      isPassed: json['isPassed'] ?? score >= passing,
    );
  }
}

class TestResultDetailModel {
  final int id;
  final int testId;
  final String testTitle;
  final double scorePercentage;
  final int passingScore;
  final int correctAnswers;
  final int totalQuestions;
  final int cheatAttempts;
  final bool autoSubmitted;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? timeLimitMinutes;
  final bool isPassed;

  TestResultDetailModel({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.scorePercentage,
    this.passingScore = 70,
    required this.correctAnswers,
    required this.totalQuestions,
    this.cheatAttempts = 0,
    this.autoSubmitted = false,
    this.startedAt,
    this.finishedAt,
    this.timeLimitMinutes,
    required this.isPassed,
  });
  Duration? get elapsed {
    if (startedAt == null || finishedAt == null) return null;
    final diff = finishedAt!.difference(startedAt!);
    return diff.isNegative ? Duration.zero : diff;
  }

  factory TestResultDetailModel.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] ?? json['scorePercentage'] ?? 0.0).toDouble();
    final passing = (json['passingScore'] ?? 70).toInt();
    return TestResultDetailModel(
      id: json['id'] ?? json['testResultId'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      scorePercentage: score,
      passingScore: passing,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      cheatAttempts: json['cheatAttempts'] ?? 0,
      autoSubmitted: json['autoSubmitted'] ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      timeLimitMinutes: json['timeLimitMinutes'],
      isPassed: json['isPassed'] ?? score >= passing,
    );
  }
}
