/// Simplified Test Model
class TestModel {
  final int id;
  final String title;
  final String? description;
  final int? questionCount;
  final DateTime? createdAt;
  final int? lectureId;
  final String? lectureTitle;

  TestModel({
    required this.id,
    required this.title,
    this.description,
    this.questionCount,
    this.createdAt,
    this.lectureId,
    this.lectureTitle,
  });
}

/// Simplified Test Detail Model
class TestDetailModel {
  final int id;
  final String title;
  final String? description;
  final List<QuestionModel> questions;

  TestDetailModel({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
  });
}

/// Simplified Question Model
class QuestionModel {
  final int id;
  final String questionText;
  final List<AnswerModel> answers;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.answers,
  });
}

/// Simplified Answer Model
class AnswerModel {
  final int id;
  final String answerText;
  final bool isCorrect;

  AnswerModel({
    required this.id,
    required this.answerText,
    this.isCorrect = false,
  });
}

/// Test DTO
class TestDto {
  final int id;
  final int? lectureId;
  final String? lectureTitle;
  final String title;
  final String? description;
  final String creatorUsername;
  final DateTime createdAt;
  final int questionsCount;

  TestDto({
    required this.id,
    this.lectureId,
    this.lectureTitle,
    required this.title,
    this.description,
    required this.creatorUsername,
    required this.createdAt,
    required this.questionsCount,
  });

  factory TestDto.fromJson(Map<String, dynamic> json) {
    return TestDto(
      id: json['id'] ?? 0,
      lectureId: json['lectureId'],
      lectureTitle: json['lectureTitle'],
      title: json['title'] ?? '',
      description: json['description'],
      creatorUsername: json['creatorUsername'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      questionsCount: json['questionsCount'] ?? 0,
    );
  }
}

/// Test Detail DTO with questions
class TestDetailDto {
  final int id;
  final int? lectureId;
  final String? lectureTitle;
  final String title;
  final String? description;
  final String creatorUsername;
  final DateTime createdAt;
  final List<QuestionDto> questions;

  TestDetailDto({
    required this.id,
    this.lectureId,
    this.lectureTitle,
    required this.title,
    this.description,
    required this.creatorUsername,
    required this.createdAt,
    required this.questions,
  });

  factory TestDetailDto.fromJson(Map<String, dynamic> json) {
    return TestDetailDto(
      id: json['id'] ?? 0,
      lectureId: json['lectureId'],
      lectureTitle: json['lectureTitle'],
      title: json['title'] ?? '',
      description: json['description'],
      creatorUsername: json['creatorUsername'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  int get questionsCount => questions.length;
}

/// Question DTO
class QuestionDto {
  final int id;
  final String questionText;
  final int position;
  final List<AnswerDto> answers;

  QuestionDto({
    required this.id,
    required this.questionText,
    required this.position,
    required this.answers,
  });

  factory QuestionDto.fromJson(Map<String, dynamic> json) {
    return QuestionDto(
      id: json['id'] ?? 0,
      questionText: json['questionText'] ?? '',
      position: json['position'] ?? 0,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Answer DTO
class AnswerDto {
  final int id;
  final String answerText;
  final int position;
  final bool? isCorrect; // Only for admin

  AnswerDto({
    required this.id,
    required this.answerText,
    required this.position,
    this.isCorrect,
  });

  factory AnswerDto.fromJson(Map<String, dynamic> json) {
    return AnswerDto(
      id: json['id'] ?? 0,
      answerText: json['answerText'] ?? '',
      position: json['position'] ?? 0,
      isCorrect: json['isCorrect'],
    );
  }
}

/// Create Test Request
class CreateTestRequest {
  final int? lectureId;
  final String title;
  final String? description;
  final List<CreateQuestionRequest> questions;

  CreateTestRequest({
    this.lectureId,
    required this.title,
    this.description,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'lectureId': lectureId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

/// Create Question Request
class CreateQuestionRequest {
  final String questionText;
  final int position;
  final List<CreateAnswerRequest> answers;

  CreateQuestionRequest({
    required this.questionText,
    required this.position,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'position': position,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

/// Create Answer Request
class CreateAnswerRequest {
  final String answerText;
  final bool isCorrect;
  final int position;

  CreateAnswerRequest({
    required this.answerText,
    required this.isCorrect,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'answerText': answerText,
      'isCorrect': isCorrect,
      'position': position,
    };
  }
}

/// Update Test Request
class UpdateTestRequest {
  final int? lectureId;
  final String? title;
  final String? description;

  UpdateTestRequest({
    this.lectureId,
    this.title,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (lectureId != null) map['lectureId'] = lectureId;
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    return map;
  }
}
