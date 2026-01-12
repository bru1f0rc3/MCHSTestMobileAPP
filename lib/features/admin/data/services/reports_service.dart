import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';

/// Reports Service Provider
final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(ref.watch(dioProvider));
});

/// Reports Service
class ReportsService {
  final Dio _dio;

  ReportsService(this._dio);

  /// Get user statistics for a specific user
  Future<ApiResponse<UserStatisticsDto>> getUserStatistics(int userId) async {
    try {
      final response = await _dio.get('${ApiConfig.reports}/user/$userId');
      return ApiResponse.fromJson(
        response.data,
        (json) => UserStatisticsDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get my statistics
  Future<ApiResponse<UserStatisticsDto>> getMyStatistics() async {
    try {
      final response = await _dio.get('${ApiConfig.reports}/my-stats');
      return ApiResponse.fromJson(
        response.data,
        (json) => UserStatisticsDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get overall system statistics (admin only)
  Future<ApiResponse<OverallStatisticsDto>> getOverallStatistics() async {
    try {
      final response = await _dio.get('${ApiConfig.reports}/overall');
      return ApiResponse.fromJson(
        response.data,
        (json) => OverallStatisticsDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get test statistics (admin only)
  Future<ApiResponse<PagedResponse<TestStatisticsDto>>> getTestStatistics({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.reports}/tests',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => TestStatisticsDto.fromJson(item),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user performance report (admin only)
  Future<ApiResponse<PagedResponse<UserPerformanceDto>>> getUsersPerformance({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.reports}/users-performance',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => UserPerformanceDto.fromJson(item),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Generate detailed report (admin only)
  Future<ApiResponse<DetailedReportDto>> generateDetailedReport({
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    int? testId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (userId != null) {
        queryParams['userId'] = userId;
      }
      if (testId != null) {
        queryParams['testId'] = testId;
      }

      final response = await _dio.get(
        '${ApiConfig.reports}/detailed',
        queryParameters: queryParams,
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => DetailedReportDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
