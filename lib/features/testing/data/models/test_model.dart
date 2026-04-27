class TestModel {
  final int id;
  final String title;
  final String? description;
  final int? questionCount;
  final DateTime? createdAt;
  final int? lectureId;
  final String? lectureTitle;
  final int? timeLimitMinutes;
  final int passingScore;

  TestModel({
    required this.id,
    required this.title,
    this.description,
    this.questionCount,
    this.createdAt,
    this.lectureId,
    this.lectureTitle,
    this.timeLimitMinutes,
    this.passingScore = 70,
  });
}

class TestDetailModel {
  final int id;
  final String title;
  final String? description;
  final int? lectureId;
  final String? lectureTitle;
  final int? timeLimitMinutes;
  final int passingScore;
  final List<QuestionModel> questions;

  TestDetailModel({
    required this.id,
    required this.title,
    this.description,
    this.lectureId,
    this.lectureTitle,
    this.timeLimitMinutes,
    this.passingScore = 70,
    required this.questions,
  });
}

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

class TestDto {
  final int id;
  final int? lectureId;
  final String? lectureTitle;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final int passingScore;
  final String creatorUsername;
  final DateTime createdAt;
  final int questionsCount;

  TestDto({
    required this.id,
    this.lectureId,
    this.lectureTitle,
    required this.title,
    this.description,
    this.timeLimitMinutes,
    this.passingScore = 70,
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
      timeLimitMinutes: json['timeLimitMinutes'],
      passingScore: json['passingScore'] ?? 70,
      creatorUsername: json['creatorUsername'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      questionsCount: json['questionsCount'] ?? 0,
    );
  }
}

class TestDetailDto {
  final int id;
  final int? lectureId;
  final String? lectureTitle;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final int passingScore;
  final String creatorUsername;
  final DateTime createdAt;
  final List<QuestionDto> questions;

  TestDetailDto({
    required this.id,
    this.lectureId,
    this.lectureTitle,
    required this.title,
    this.description,
    this.timeLimitMinutes,
    this.passingScore = 70,
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
      timeLimitMinutes: json['timeLimitMinutes'],
      passingScore: json['passingScore'] ?? 70,
      creatorUsername: json['creatorUsername'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  int get questionsCount => questions.length;
}

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
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AnswerDto {
  final int id;
  final String answerText;
  final int position;
  final bool? isCorrect;

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

class CreateTestRequest {
  final int? lectureId;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final int? passingScore;
  final List<CreateQuestionRequest> questions;

  CreateTestRequest({
    this.lectureId,
    required this.title,
    this.description,
    this.timeLimitMinutes,
    this.passingScore,
    required this.questions,
  });

  Map<String, dynamic> toJson() {
    return {
      'lectureId': lectureId,
      'title': title,
      'description': description,
      'timeLimitMinutes': timeLimitMinutes,
      'passingScore': passingScore,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

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

class UpdateTestRequest {
  final int? lectureId;
  final String? title;
  final String? description;
  final int? timeLimitMinutes;
  final int? passingScore;
  final bool clearTimeLimit;

  UpdateTestRequest({
    this.lectureId,
    this.title,
    this.description,
    this.timeLimitMinutes,
    this.passingScore,
    this.clearTimeLimit = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (lectureId != null) map['lectureId'] = lectureId;
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (clearTimeLimit) {
      map['timeLimitMinutes'] = null;
    } else if (timeLimitMinutes != null) {
      map['timeLimitMinutes'] = timeLimitMinutes;
    }
    if (passingScore != null) map['passingScore'] = passingScore;
    return map;
  }
}

class UpdateQuestionRequest {
  final String? questionText;
  final int? position;

  UpdateQuestionRequest({this.questionText, this.position});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (questionText != null) map['questionText'] = questionText;
    if (position != null) map['position'] = position;
    return map;
  }
}

class UpdateAnswerRequest {
  final String? answerText;
  final bool? isCorrect;
  final int? position;

  UpdateAnswerRequest({this.answerText, this.isCorrect, this.position});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (answerText != null) map['answerText'] = answerText;
    if (isCorrect != null) map['isCorrect'] = isCorrect;
    if (position != null) map['position'] = position;
    return map;
  }
}
