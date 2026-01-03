import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class UserService {
  static const String _userIdKey = 'user_id';

  /// Get or create a persistent user ID
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user ID already exists
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      // Generate new user ID
      userId = _uuid.v4();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  /// Clear user ID (for testing/debugging)
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
