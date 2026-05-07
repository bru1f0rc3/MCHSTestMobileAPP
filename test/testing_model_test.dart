import 'package:flutter_test/flutter_test.dart';
import 'package:mchs_mobile_app/models/testing_model.dart';

void main() {
  group('SubmitAnswerRequest', () {
    test('toJson serializes fields', () {
      final r = SubmitAnswerRequest(questionId: 1, answerId: 2);
      expect(r.toJson(), {'questionId': 1, 'answerId': 2});
    });
  });

  group('SubmitAnswersRequest', () {
    test('toJson wraps answers list', () {
      final r = SubmitAnswersRequest(answers: [
        SubmitAnswerRequest(questionId: 1, answerId: 10),
        SubmitAnswerRequest(questionId: 2, answerId: 20),
      ]);

      expect(r.toJson(), {
        'answers': [
          {'questionId': 1, 'answerId': 10},
          {'questionId': 2, 'answerId': 20},
        ]
      });
    });
  });

  group('FinishTestResponse.fromJson', () {
    test('parses passed status', () {
      final response = FinishTestResponse.fromJson({
        'testResultId': 1,
        'testTitle': 'Тест',
        'startedAt': '2025-01-01T10:00:00Z',
        'finishedAt': '2025-01-01T10:30:00Z',
        'score': 85.0,
        'status': 'passed',
        'totalQuestions': 10,
        'correctAnswers': 8,
      });

      expect(response.score, 85.0);
      expect(response.isPassed, isTrue);
      expect(response.totalQuestions, 10);
      expect(response.correctAnswers, 8);
    });

    test('parses failed status', () {
      final response = FinishTestResponse.fromJson({
        'testResultId': 1,
        'testTitle': 'Тест',
        'startedAt': '2025-01-01T10:00:00Z',
        'finishedAt': '2025-01-01T10:30:00Z',
        'score': 50.0,
        'status': 'failed',
        'totalQuestions': 10,
        'correctAnswers': 5,
      });

      expect(response.isPassed, isFalse);
    });

    test('duration is finishedAt minus startedAt', () {
      final r = FinishTestResponse(
        testResultId: 1,
        testTitle: 'T',
        startedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        finishedAt: DateTime.utc(2025, 1, 1, 10, 25, 0),
        score: 100,
        status: 'passed',
        totalQuestions: 10,
        correctAnswers: 10,
      );

      expect(r.duration, const Duration(minutes: 25));
    });
  });

  group('TestResultDto status flags', () {
    TestResultDto build(String status) => TestResultDto(
          id: 1,
          testId: 1,
          testTitle: 'T',
          startedAt: DateTime.now(),
          status: status,
        );

    test('passed', () {
      final r = build('passed');
      expect(r.isPassed, isTrue);
      expect(r.isFailed, isFalse);
      expect(r.isInProgress, isFalse);
    });

    test('failed', () {
      final r = build('failed');
      expect(r.isFailed, isTrue);
      expect(r.isPassed, isFalse);
    });

    test('in_progress', () {
      final r = build('in_progress');
      expect(r.isInProgress, isTrue);
      expect(r.isFinished, isFalse);
    });

    test('isFinished when finishedAt set', () {
      final r = TestResultDto(
        id: 1,
        testId: 1,
        testTitle: 'T',
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
        status: 'passed',
      );
      expect(r.isFinished, isTrue);
    });
  });

  group('TestResultDetailModel.elapsed', () {
    test('returns difference', () {
      final r = TestResultDetailModel(
        id: 1,
        testId: 1,
        testTitle: 'T',
        scorePercentage: 80,
        correctAnswers: 8,
        totalQuestions: 10,
        startedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        finishedAt: DateTime.utc(2025, 1, 1, 10, 15, 0),
        isPassed: true,
      );

      expect(r.elapsed, const Duration(minutes: 15));
    });

    test('returns null when timestamps missing', () {
      final r = TestResultDetailModel(
        id: 1,
        testId: 1,
        testTitle: 'T',
        scorePercentage: 0,
        correctAnswers: 0,
        totalQuestions: 0,
        isPassed: false,
      );

      expect(r.elapsed, isNull);
    });

    test('returns zero when finishedAt before startedAt', () {
      final r = TestResultDetailModel(
        id: 1,
        testId: 1,
        testTitle: 'T',
        scorePercentage: 0,
        correctAnswers: 0,
        totalQuestions: 0,
        startedAt: DateTime.utc(2025, 1, 1, 11, 0, 0),
        finishedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
        isPassed: false,
      );

      expect(r.elapsed, Duration.zero);
    });
  });

  group('TestResultModel.fromJson', () {
    test('uses score field if present', () {
      final m = TestResultModel.fromJson({
        'id': 1,
        'testId': 5,
        'score': 75.0,
        'passingScore': 70,
        'correctAnswers': 7,
        'totalQuestions': 10,
      });

      expect(m.scorePercentage, 75.0);
      expect(m.isPassed, isTrue);
    });

    test('isPassed false when below passingScore', () {
      final m = TestResultModel.fromJson({
        'id': 1,
        'testId': 5,
        'score': 50.0,
        'passingScore': 70,
        'correctAnswers': 5,
        'totalQuestions': 10,
      });

      expect(m.isPassed, isFalse);
    });
  });
}
