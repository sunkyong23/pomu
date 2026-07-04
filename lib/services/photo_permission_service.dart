import 'package:photo_manager/photo_manager.dart';

class PhotoPermissionService {
  Future<PermissionState> requestPermission() async {
    return PhotoManager.requestPermissionExtend();
  }

  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  bool hasAccess(PermissionState state) {
    return state.hasAccess;
  }
}
