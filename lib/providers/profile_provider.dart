import 'package:flutter/foundation.dart';
import 'package:spendwise/models/profile.dart';
import 'package:spendwise/services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  Profile? get profile => _profile;

  void applyFromData(Map<String, dynamic>? data) {
    if (data == null) return;
    _profile = Profile.fromJson(data);
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final data = await AuthService().getProfile();
      applyFromData(data);
    } catch (e) {
      debugPrint('ProfileProvider.load: $e');
    }
  }

  Future<void> updateAvatar(String avatarId) async {
    await AuthService().updateProfile(avatar: avatarId);
    if (_profile != null) {
      _profile = _profile!.copyWith(avatar: avatarId);
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
