import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/core/constants/app_constants.dart';
import 'package:mchs_mobile_app/core/models/api_response.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:mchs_mobile_app/features/admin/data/models/pdf_import_model.dart';

final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  return PdfImportService(ref.watch(dioProvider));
});

class PdfImportService {
  final Dio _dio;

  PdfImportService(this._dio);
  Future<ApiResponse<ImportTestResultDto>> importTestFromPdf({
    required File pdfFile,
    required int lectureId,
    required String title,
    String? description,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = pdfFile.path.split('/').last;
      final formData = FormData.fromMap({
        'lectureId': lectureId,
        'title': title,
        'description': description ?? '',
        'pdfFile': await MultipartFile.fromFile(
          pdfFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '${ApiConfig.tests}/import-from-pdf',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => ImportTestResultDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<ImportTestResultDto>> importTestFromPdfBytes({
    required Uint8List pdfBytes,
    required String fileName,
    required int lectureId,
    required String title,
    String? description,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'lectureId': lectureId,
        'title': title,
        'description': description ?? '',
        'pdfFile': MultipartFile.fromBytes(pdfBytes, filename: fileName),
      });

      final response = await _dio.post(
        '${ApiConfig.tests}/import-from-pdf',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => ImportTestResultDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<UploadMediaResultDto>> uploadVideo({
    required File videoFile,
    required int lectureId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = videoFile.path.split('/').last;
      final formData = FormData.fromMap({
        'lectureId': lectureId,
        'videoFile': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '${ApiConfig.lectures}/upload-video',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UploadMediaResultDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<UploadMediaResultDto>> uploadPdfDocument({
    required File pdfFile,
    required int lectureId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = pdfFile.path.split('/').last;
      final formData = FormData.fromMap({
        'lectureId': lectureId,
        'pdfFile': await MultipartFile.fromFile(
          pdfFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '${ApiConfig.lectures}/upload-document',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UploadMediaResultDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
