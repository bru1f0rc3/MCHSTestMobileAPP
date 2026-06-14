/// Файл из серверного хранилища (видео или PDF).
class StorageFileModel {
  /// Имя файла, например "intro.mp4".
  final String name;

  /// Относительный путь внутри хранилища, например "videos/intro.mp4".
  /// Именно он сохраняется в лекцию.
  final String path;

  final int sizeBytes;
  final String extension;

  StorageFileModel({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.extension,
  });

  factory StorageFileModel.fromJson(Map<String, dynamic> json) {
    return StorageFileModel(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      extension: json['extension'] ?? '',
    );
  }

  /// Человекочитаемый размер файла.
  String get readableSize {
    if (sizeBytes <= 0) return '';
    const units = ['Б', 'КБ', 'МБ', 'ГБ'];
    var size = sizeBytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$value ${units[unit]}';
  }
}
