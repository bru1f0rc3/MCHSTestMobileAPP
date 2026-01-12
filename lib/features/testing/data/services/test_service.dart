import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';
import 'package:mchs_mobile_app/features/testing/data/models/testing_model.dart';

/// Test Service Provider
final testServiceProvider = Provider<TestService>((ref) {
  return TestService(ref.watch(dioProvider));
});

/// Test Service
class TestService {
  final Dio _dio;

  TestService(this._dio);

  /// Get all tests (for admin)
  Future<List<TestModel>> getAllTests({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.tests,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestDto.fromJson(item),
        ),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items.map((dto) => TestModel(
          id: dto.id,
          title: dto.title,
          description: dto.description,
          questionCount: dto.questionsCount,
          createdAt: dto.createdAt,
          lectureId: dto.lectureId,
          lectureTitle: dto.lectureTitle,
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get available tests (not yet passed by user) - for regular users
  Future<List<TestModel>> getTests({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.availableTests,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestDto.fromJson(item),
        ),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items.map((dto) => TestModel(
          id: dto.id,
          title: dto.title,
          description: dto.description,
          questionCount: dto.questionsCount,
          createdAt: dto.createdAt,
          lectureId: dto.lectureId,
          lectureTitle: dto.lectureTitle,
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get test detail
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
          questions: dto.questions.map((q) => QuestionModel(
            id: q.id,
            questionText: q.questionText,
            answers: q.answers.map((a) => AnswerModel(
              id: a.id,
              answerText: a.answerText,
              isCorrect: a.isCorrect ?? false,
            )).toList(),
          )).toList(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Start test
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

  /// Submit answers
  Future<void> submitAnswers(int testResultId, List<Map<String, dynamic>> answers) async {
    try {
      // Преобразуем формат: из {questionId, answerIds[]} в несколько {questionId, answerId}
      final List<Map<String, dynamic>> formattedAnswers = [];
      for (var answer in answers) {
        final questionId = answer['questionId'];
        final answerIds = answer['answerIds'] as List;
        
        // Для каждого ответа создаем отдельную запись
        for (var answerId in answerIds) {
          formattedAnswers.add({
            'questionId': questionId,
            'answerId': answerId,
          });
        }
      }
      
      // API ожидает поле 'Answers' с заглавной буквы
      await _dio.post(
        '${ApiConfig.testing}/$testResultId/answers',
        data: {
          'answers': formattedAnswers,  // Поле должно быть lowercase согласно C# DTO
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Finish test
  Future<FinishTestResponse> finishTest(int testResultId) async {
    try {
      final response = await _dio.post('${ApiConfig.testing}/$testResultId/finish');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => FinishTestResponse.fromJson(json),
      );
      return apiResponse.data!;
    } catch (e) {
      rethrow;
    }
  }

  /// Get test history
  Future<List<TestResultModel>> getTestHistory({int page = 1, int pageSize = 50}) async {
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

  /// Get test result detail
  Future<TestResultDetailModel?> getTestResult(int testResultId) async {
    try {
      final response = await _dio.get('${ApiConfig.testing}/result/$testResultId');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => TestResultDetailModel.fromJson(json),
      );
      return apiResponse.data;
    } catch (e) {
      return null;
    }
  }

  /// Update test (admin only)
  Future<ApiResponse<bool>> update(int id, UpdateTestRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.tests}/$id',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Delete test (admin only)
  Future<ApiResponse<bool>> delete(int id) async {
    try {
      final response = await _dio.delete('${ApiConfig.tests}/$id');
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create test (admin only)
  Future<ApiResponse<TestDto>> create(CreateTestRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.tests,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => TestDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Testing Service Provider
final testingServiceProvider = Provider<TestingService>((ref) {
  return TestingService(ref.watch(dioProvider));
});

/// Testing Service (for taking tests)
class TestingService {
  final Dio _dio;

  TestingService(this._dio);

  /// Start test
  Future<ApiResponse<StartTestResponse>> startTest(int testId) async {
    try {
      final response = await _dio.post('${ApiConfig.testing}/start/$testId');
      return ApiResponse.fromJson(
        response.data,
        (json) => StartTestResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submit single answer
  Future<ApiResponse<bool>> submitAnswer(
    int testResultId,
    SubmitAnswerRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.testing}/$testResultId/answer',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Submit multiple answers
  Future<ApiResponse<bool>> submitAnswers(
    int testResultId,
    SubmitAnswersRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.testing}/$testResultId/answers',
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Finish test
  Future<ApiResponse<FinishTestResponse>> finishTest(int testResultId) async {
    try {
      final response = await _dio.post('${ApiConfig.testing}/$testResultId/finish');
      return ApiResponse.fromJson(
        response.data,
        (json) => FinishTestResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get test result
  Future<ApiResponse<TestResultDto>> getResult(int testResultId) async {
    try {
      final response = await _dio.get('${ApiConfig.testing}/result/$testResultId');
      return ApiResponse.fromJson(
        response.data,
        (json) => TestResultDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get detailed test result
  Future<ApiResponse<TestResultDetailDto>> getResultDetail(int testResultId) async {
    try {
      final response = await _dio.get('${ApiConfig.testing}/result/$testResultId/detail');
      return ApiResponse.fromJson(
        response.data,
        (json) => TestResultDetailDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get my results with pagination
  Future<ApiResponse<PagedResponse<TestResultDto>>> getMyResults({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.testing}/my-results',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestResultDto.fromJson(item),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get all results (admin only)
  Future<ApiResponse<PagedResponse<TestResultDto>>> getAllResults({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.testing}/all-results',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestResultDto.fromJson(item),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
