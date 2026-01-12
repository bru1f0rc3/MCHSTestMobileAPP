import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/lectures/data/models/lecture_model.dart';

/// Lecture Service Provider
final lectureServiceProvider = Provider<LectureService>((ref) {
  return LectureService(ref.watch(dioProvider));
});

/// Lecture Service
class LectureService {
  final Dio _dio;

  LectureService(this._dio);

  /// Get lectures (simplified)
  Future<List<LectureModel>> getLectures({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.lectures,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => PagedResponse.fromJson(
          json,
          (item) => LectureListDto.fromJson(item),
        ),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.items.map((dto) => LectureModel(
          id: dto.id,
          title: dto.title,
          textContent: null,
          createdAt: dto.createdAt,
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get lecture by ID
  Future<LectureModel?> getLectureById(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.lectures}/$id');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => LectureDto.fromJson(json),
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        final dto = apiResponse.data!;
        return LectureModel(
          id: dto.id,
          title: dto.title,
          textContent: dto.textContent,
          videoPath: dto.videoPath,
          documentPath: dto.documentPath,
          createdAt: dto.createdAt,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create lecture (admin only)
  Future<ApiResponse<LectureDto>> create(CreateLectureRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.lectures,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => LectureDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Update lecture (admin only)
  Future<ApiResponse<bool>> update(int id, UpdateLectureRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.lectures}/$id',
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

  /// Delete lecture (admin only)
  Future<ApiResponse<bool>> delete(int id) async {
    try {
      final response = await _dio.delete('${ApiConfig.lectures}/$id');
      return ApiResponse.fromJson(
        response.data,
        (json) => json as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
