/// Import Test Result DTO
class ImportTestResultDto {
  final int testId;
  final String title;
  final int questionsImported;
  final int totalQuestions;
  final List<String> errors;

  ImportTestResultDto({
    required this.testId,
    required this.title,
    required this.questionsImported,
    required this.totalQuestions,
    required this.errors,
  });

  factory ImportTestResultDto.fromJson(Map<String, dynamic> json) {
    return ImportTestResultDto(
      testId: json['testId'] ?? 0,
      title: json['title'] ?? '',
      questionsImported: json['questionsImported'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      errors: (json['errors'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get isComplete => questionsImported == totalQuestions && !hasErrors;
}

/// Upload Media Result DTO
class UploadMediaResultDto {
  final String url;
  final String fileName;
  final int fileSize;
  final String contentType;

  UploadMediaResultDto({
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
  });

  factory UploadMediaResultDto.fromJson(Map<String, dynamic> json) {
    return UploadMediaResultDto(
      url: json['url'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      contentType: json['contentType'] ?? '',
    );
  }
}
