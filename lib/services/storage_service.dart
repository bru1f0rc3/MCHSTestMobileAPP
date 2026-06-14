import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mchs_mobile_app/config/app_config.dart';
import 'package:mchs_mobile_app/config/dio_client.dart';
import 'package:mchs_mobile_app/models/api_response.dart';
import 'package:mchs_mobile_app/models/storage_file_model.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(dioProvider));
});

/// Тип материала в хранилище.
enum StorageFileType {
  video,
  document;

  String get apiValue => this == StorageFileType.video ? 'video' : 'document';

  /// Разрешённые расширения (без точки) — для фильтра выбора файла на устройстве.
  List<String> get allowedExtensions => this == StorageFileType.video
      ? const ['mp4', 'webm', 'm4v', 'mov', 'mkv', 'ogg', 'ogv', 'avi']
      : const ['pdf'];
}

class StorageService {
  final Dio _dio;

  StorageService(this._dio);

  /// Список файлов в серверной папке хранилища (только для админов).
  Future<List<StorageFileModel>> browse(StorageFileType type) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.storageBrowse,
        queryParameters: {'type': type.apiValue},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => (json as List)
            .map((e) => StorageFileModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data ?? [];
    } catch (e) {
      developer.log('storage browse error: $e', name: 'StorageService');
      rethrow;
    }
  }

  /// Загружает файл с устройства в серверное хранилище.
  ///
  /// Поддерживает и мобильные платформы (через [filePath]), и веб (через [bytes]).
  /// Возвращает описание сохранённого файла с относительным путём.
  Future<StorageFileModel?> upload(
    StorageFileType type, {
    required String fileName,
    String? filePath,
    List<int>? bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    final MultipartFile multipart;
    if (bytes != null) {
      multipart = MultipartFile.fromBytes(bytes, filename: fileName);
    } else if (filePath != null) {
      multipart = await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      throw ArgumentError('Нужно передать filePath или bytes');
    }

    final formData = FormData.fromMap({'file': multipart});

    final response = await _dio.post(
      ApiEndpoints.storageUpload,
      queryParameters: {'type': type.apiValue},
      data: formData,
      onSendProgress: onProgress,
      options: Options(
        // Заливка крупных видео может идти долго — снимаем таймауты.
        sendTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => StorageFileModel.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Не удалось загрузить файл');
    }
    return apiResponse.data;
  }
}

/// Сборка абсолютных URL для отдачи файлов из хранилища.
class StorageUrls {
  StorageUrls._();

  /// Полный URL для стриминга файла по сохранённому в лекции значению.
  ///
  /// Если значение уже является абсолютной ссылкой (старые лекции с http-URL),
  /// возвращаем его без изменений. Иначе считаем это относительным путём
  /// внутри хранилища и строим ссылку на эндпоинт /storage/file.
  static String fileUrl(String pathOrUrl) {
    final value = pathOrUrl.trim();
    if (value.isEmpty) return value;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }

    final relative = value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    return '$base${ApiEndpoints.storageFile}?path=${Uri.encodeQueryComponent(relative)}';
  }
}
