import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  // Demande la permission de stockage
  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.status.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Vérifie si la permission de stockage est accordée
  Future<bool> checkStoragePermission() async {
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  // Demande la permission de stockage
  Future<bool> requestAllPermissions() async {
    return await requestStoragePermission();
  }
} 