import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/data/models/testing_model.dart';

final testServiceProvider = Provider<TestService>((ref) {
  return TestService(ref.watch(dioProvider));
});

class TestService {
  final Dio _dio;

  TestService(this._dio);
  Future<List<TestModel>> getAllTests({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.tests,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) =>
            PagedResponse.fromJson(json, (item) => TestDto.fromJson(item)),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items.map(_toTestModel).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<TestModel>> getTests({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.availableTests,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) =>
            PagedResponse.fromJson(json, (item) => TestDto.fromJson(item)),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items.map(_toTestModel).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  TestModel _toTestModel(TestDto dto) => TestModel(
    id: dto.id,
    title: dto.title,
    description: dto.description,
    questionCount: dto.questionsCount,
    createdAt: dto.createdAt,
    lectureId: dto.lectureId,
    lectureTitle: dto.lectureTitle,
    timeLimitMinutes: dto.timeLimitMinutes,
    passingScore: dto.passingScore,
  );
  Future<TestDetailModel?> getTestDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.tests}/$id/full');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => TestDetailDto.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final dto = apiResponse.data!;
        return TestDetailModel(
          id: dto.id,
          title: dto.title,
          description: dto.description,
          lectureId: dto.lectureId,
          lectureTitle: dto.lectureTitle,
          timeLimitMinutes: dto.timeLimitMinutes,
          passingScore: dto.passingScore,
          questions: dto.questions
              .map(
                (q) => QuestionModel(
                  id: q.id,
                  questionText: q.questionText,
                  answers: q.answers
                      .map(
                        (a) => AnswerModel(
                          id: a.id,
                          answerText: a.answerText,
                          isCorrect: a.isCorrect ?? false,
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<StartTestResponse> startTest(int testId) async {
    try {
      final response = await _dio.post('${ApiConfig.testing}/start/$testId');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => StartTestResponse.fromJson(json),
      );
      return apiResponse.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAnswers(
    int testResultId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final List<Map<String, dynamic>> formattedAnswers = [];
      for (var answer in answers) {
        final questionId = answer['questionId'];
        final answerIds = answer['answerIds'] as List;
        for (var answerId in answerIds) {
          formattedAnswers.add({
            'questionId': questionId,
            'answerId': answerId,
          });
        }
      }
      await _dio.post(
        '${ApiConfig.testing}/$testResultId/answers',
        data: {'answers': formattedAnswers},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<FinishTestResponse> finishTest(int testResultId) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.testing}/$testResultId/finish',
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => FinishTestResponse.fromJson(json),
      );
      return apiResponse.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reportCheatAttempt(
    int testResultId, {
    String eventType = 'app_background',
    String? details,
  }) async {
    try {
      await _dio.post(
        '${ApiConfig.testing}/$testResultId/cheat-attempt',
        data: ReportCheatAttemptRequest(
          eventType: eventType,
          details: details,
        ).toJson(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>?> exportMyResultsCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _downloadCsv(
      '${ApiConfig.testing}/my-results/export',
      startDate,
      endDate,
      null,
    );
  }

  Future<List<int>?> exportAllResultsCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    return _downloadCsv(
      '${ApiConfig.testing}/all-results/export',
      startDate,
      endDate,
      searchQuery,
    );
  }

  Future<List<int>?> _downloadCsv(
    String path,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  ) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate.toIso8601String();
      if (endDate != null) query['endDate'] = endDate.toIso8601String();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query['searchQuery'] = searchQuery;
      }

      final response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<List<TestResultModel>> getTestHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.testing}/my-results',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestResultModel.fromJson(item),
        ),
      );
      return apiResponse.data?.items ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<TestResultDetailModel?> getTestResult(int testResultId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.testing}/result/$testResultId',
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => TestResultDetailModel.fromJson(json),
      );
      return apiResponse.data;
    } catch (e) {
      return null;
    }
  }

  Future<ApiResponse<bool>> update(int id, UpdateTestRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.tests}/$id',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<bool>> delete(int id) async {
    try {
      final response = await _dio.delete('${ApiConfig.tests}/$id');
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<TestDto>> create(CreateTestRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.tests, data: request.toJson());
      return ApiResponse.fromJson(
        response.data,
        (json) => TestDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<QuestionDto>> addQuestion(
    int testId,
    CreateQuestionRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.tests}/$testId/questions',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => QuestionDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<bool>> updateQuestion(
    int questionId,
    UpdateQuestionRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.tests}/questions/$questionId',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<bool>> deleteQuestion(int questionId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.tests}/questions/$questionId',
      );
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<AnswerDto>> addAnswer(
    int questionId,
    CreateAnswerRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.tests}/questions/$questionId/answers',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => AnswerDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<bool>> updateAnswer(
    int answerId,
    UpdateAnswerRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.tests}/answers/$answerId',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<bool>> deleteAnswer(int answerId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.tests}/answers/$answerId',
      );
      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
