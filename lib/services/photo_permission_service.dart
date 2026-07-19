import 'package:photo_manager/photo_manager.dart';

class PhotoPermissionService {
  /// 현재 사진 접근 권한 상태를 확인합니다.
  Future<PermissionState> getPermissionState() async {
    return PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
  }

  /// 사진 접근 권한을 요청합니다.
  Future<PermissionState> requestPermission() async {
    return PhotoManager.requestPermissionExtend();
  }

  /// 설정 화면을 엽니다.
  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  bool hasAccess(PermissionState state) {
    return state.hasAccess;
  }
}
