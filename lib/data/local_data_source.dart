import 'package:shared_preferences/shared_preferences.dart';

class FeedbackLocalDataSource {
  static const String _keyHasSeenFeedback = 'has_seen_feedback_notification';

  Future<bool> getHasSeenFeedbackNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenFeedback) ?? false;
  }

  Future<void> setHasSeenFeedbackNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenFeedback, value);
  }
}
