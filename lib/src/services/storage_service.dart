import 'package:shared_preferences/shared_preferences.dart';
import '../utils/utils.dart';

/// A wrapper around [SharedPreferences] for simple key-value persistence.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const onboardingCompletedKey = 'onboarding_completed';
  static const lastAccessedWeddingKey = 'last_accessed_wedding_id';

  late final SharedPreferences _prefs;

  /// Initialize SharedPreferences instance.
  FutureEither<void> init() async {
    return runTask(() async {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('StorageService (SharedPreferences) initialized');
    });
  }

  // --- SETTERS ---

  FutureEither<bool> setString(String key, String value) async =>
      runTask(() => _prefs.setString(key, value));

  FutureEither<bool> setBool(String key, bool value) async =>
      runTask(() => _prefs.setBool(key, value));

  FutureEither<bool> setInt(String key, int value) async =>
      runTask(() => _prefs.setInt(key, value));

  FutureEither<bool> setDouble(String key, double value) async =>
      runTask(() => _prefs.setDouble(key, value));

  FutureEither<bool> setStringList(String key, List<String> value) async =>
      runTask(() => _prefs.setStringList(key, value));

  // --- GETTERS ---

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // --- COMMON ---

  bool containsKey(String key) => _prefs.containsKey(key);

  bool get hasCompletedOnboarding => getBool(onboardingCompletedKey) ?? false;

  FutureEither<bool> markOnboardingCompleted() =>
      setBool(onboardingCompletedKey, true);

  String? get lastAccessedWeddingId {
    try {
      return getString(lastAccessedWeddingKey);
    } catch (error, stackTrace) {
      // Unit-level consumers may use providers before app startup initializes
      // SharedPreferences; absence of a remembered list is the safe default.
      AppLogger.error(
          'Unable to read the last accessed list', error, stackTrace);
      return null;
    }
  }

  FutureEither<bool> setLastAccessedWeddingId(String id) =>
      setString(lastAccessedWeddingKey, id);

  FutureEither<bool> remove(String key) async =>
      runTask(() => _prefs.remove(key));

  FutureEither<bool> clear() async => runTask(() => _prefs.clear());
}
