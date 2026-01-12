/// Simplified Lecture Model
class LectureModel {
  final int id;
  final String title;
  final String? textContent;
  final String? videoPath;
  final String? documentPath;
  final DateTime? createdAt;

  LectureModel({
    required this.id,
    required this.title,
    this.textContent,
    this.videoPath,
    this.documentPath,
    this.createdAt,
  });

  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;
  bool get hasDocument => documentPath != null && documentPath!.isNotEmpty;
}

/// Lecture List DTO
class LectureListDto {
  final int id;
  final String title;
  final bool hasVideo;
  final bool hasDocument;
  final DateTime createdAt;

  LectureListDto({
    required this.id,
    required this.title,
    required this.hasVideo,
    required this.hasDocument,
    required this.createdAt,
  });

  factory LectureListDto.fromJson(Map<String, dynamic> json) {
    return LectureListDto(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      hasVideo: json['hasVideo'] ?? false,
      hasDocument: json['hasDocument'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Lecture Detail DTO
class LectureDto {
  final int id;
  final String title;
  final String? textContent;
  final String? videoPath;
  final String? documentPath;
  final DateTime createdAt;

  LectureDto({
    required this.id,
    required this.title,
    this.textContent,
    this.videoPath,
    this.documentPath,
    required this.createdAt,
  });

  factory LectureDto.fromJson(Map<String, dynamic> json) {
    return LectureDto(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      textContent: json['textContent'],
      videoPath: json['videoPath'],
      documentPath: json['documentPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;
  bool get hasDocument => documentPath != null && documentPath!.isNotEmpty;
}

/// Create Lecture Request
class CreateLectureRequest {
  final String title;
  final String? textContent;
  final String? videoPath;
  final String? documentPath;

  CreateLectureRequest({
    required this.title,
    this.textContent,
    this.videoPath,
    this.documentPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'textContent': textContent,
      'videoPath': videoPath,
      'documentPath': documentPath,
    };
  }
}

/// Update Lecture Request
class UpdateLectureRequest {
  final String? title;
  final String? textContent;
  final String? videoPath;
  final String? documentPath;

  UpdateLectureRequest({
    this.title,
    this.textContent,
    this.videoPath,
    this.documentPath,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (textContent != null) map['textContent'] = textContent;
    if (videoPath != null) map['videoPath'] = videoPath;
    if (documentPath != null) map['documentPath'] = documentPath;
    return map;
  }
}
