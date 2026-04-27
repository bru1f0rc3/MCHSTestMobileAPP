import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mchs_mobile_app/core/network/dio_client.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  final FlutterSecureStorage _storage;
  static const _deviceIdKey = 'device_id';

  String? _cachedDeviceId;

  DeviceIdService(this._storage);
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    String? deviceId;
    try {
      deviceId = await _getHardwareDeviceId();
    } catch (e) {
      debugPrint('DeviceIdService: Не удалось получить hardware ID: $e');
    }
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = await _storage.read(key: _deviceIdKey);
    }
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
    }
    await _storage.write(key: _deviceIdKey, value: deviceId);

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  Future<String?> _getHardwareDeviceId() async {
    if (kIsWeb) {
      return null;
    }

    final deviceInfo = DeviceInfoPlugin();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await deviceInfo.androidInfo;
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty) return androidId;
        return null;

      case TargetPlatform.iOS:
        final iosInfo = await deviceInfo.iosInfo;
        final iosId = iosInfo.identifierForVendor;
        if (iosId != null && iosId.isNotEmpty) return iosId;
        return null;

      case TargetPlatform.windows:
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;

      case TargetPlatform.linux:
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId;

      case TargetPlatform.macOS:
        final macOsInfo = await deviceInfo.macOsInfo;
        return macOsInfo.systemGUID;

      default:
        return null;
    }
  }
}

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DeviceIdService(storage);
});
