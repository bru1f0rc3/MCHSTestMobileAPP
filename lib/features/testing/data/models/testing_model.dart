/// Start Test Response
class StartTestResponse {
  final int testResultId;
  final int testId;
  final String testTitle;
  final DateTime startedAt;
  final List<TestQuestionDto> questions;

  StartTestResponse({
    required this.testResultId,
    required this.testId,
    required this.testTitle,
    required this.startedAt,
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
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => TestQuestionDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  int get questionsCount => questions.length;
}

/// Test Question DTO (for taking test)
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
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => TestAnswerDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Test Answer DTO (for taking test)
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

/// Submit Answer Request
class SubmitAnswerRequest {
  final int questionId;
  final int answerId;

  SubmitAnswerRequest({
    required this.questionId,
    required this.answerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answerId': answerId,
    };
  }
}

/// Submit Multiple Answers Request
class SubmitAnswersRequest {
  final List<SubmitAnswerRequest> answers;

  SubmitAnswersRequest({required this.answers});

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

/// Finish Test Response
class FinishTestResponse {
  final int testResultId;
  final String testTitle;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double score;
  final String status;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResultDto>? questionResults;

  FinishTestResponse({
    required this.testResultId,
    required this.testTitle,
    required this.startedAt,
    required this.finishedAt,
    required this.score,
    required this.status,
    required this.totalQuestions,
    required this.correctAnswers,
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
      status: json['status'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((e) => QuestionResultDto.fromJson(e))
          .toList(),
    );
  }

  bool get isPassed => status.toLowerCase() == 'passed';
  Duration get duration => finishedAt.difference(startedAt);
}

/// Question Result DTO
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

/// Test Result DTO (for history)
class TestResultDto {
  final int id;
  final int testId;
  final String testTitle;
  final String? lectureTitle;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? score;
  final String status;
  final int totalQuestions;
  final int correctAnswers;

  TestResultDto({
    required this.id,
    required this.testId,
    required this.testTitle,
    this.lectureTitle,
    required this.startedAt,
    this.finishedAt,
    this.score,
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
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score']?.toDouble(),
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

/// Test Result Detail DTO
class TestResultDetailDto extends TestResultDto {
  final List<QuestionResultDto> questionResults;

  TestResultDetailDto({
    required super.id,
    required super.testId,
    required super.testTitle,
    super.lectureTitle,
    required super.startedAt,
    super.finishedAt,
    super.score,
    required super.status,
    required this.questionResults,
  });

  factory TestResultDetailDto.fromJson(Map<String, dynamic> json) {
    return TestResultDetailDto(
      id: json['id'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      lectureTitle: json['lectureTitle'],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      score: json['score']?.toDouble(),
      status: json['status'] ?? '',
      questionResults: (json['questionResults'] as List<dynamic>?)
              ?.map((e) => QuestionResultDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  int get totalQuestions => questionResults.length;
  int get correctAnswers => questionResults.where((q) => q.isCorrect).length;
}

/// Simplified Test Result Model
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
      isPassed: json['isPassed'] ?? score >= 70,
    );
  }
}

/// Simplified Test Result Detail Model
class TestResultDetailModel {
  final int id;
  final int testId;
  final String testTitle;
  final double scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool isPassed;

  TestResultDetailModel({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    this.startedAt,
    this.finishedAt,
    required this.isPassed,
  });

  factory TestResultDetailModel.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] ?? json['scorePercentage'] ?? 0.0).toDouble();
    return TestResultDetailModel(
      id: json['id'] ?? json['testResultId'] ?? 0,
      testId: json['testId'] ?? 0,
      testTitle: json['testTitle'] ?? '',
      scorePercentage: score,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      isPassed: json['isPassed'] ?? score >= 70,
    );
  }
}
