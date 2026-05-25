import 'package:shared_preferences/shared_preferences.dart';

/// Persistent preferences for delete confirmation dialogs.
///
/// Wraps [SharedPreferences] behind Riverpod for testability (override with
/// in-memory impl in widget tests).
class DeleteConfirmPrefs {
  DeleteConfirmPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _keySingle = 'confirmDeleteSingleItem';
  static const _keyBatch = 'confirmDeleteBatchItems';

  /// Whether to show confirmation dialog before deleting a single item.
  bool get confirmDeleteSingleItem =>
      _prefs.getBool(_keySingle) ?? true;

  Future<void> setConfirmDeleteSingleItem(bool value) =>
      _prefs.setBool(_keySingle, value);

  /// Whether to show confirmation dialog before batch-deleting items.
  bool get confirmDeleteBatchItems =>
      _prefs.getBool(_keyBatch) ?? true;

  Future<void> setConfirmDeleteBatchItems(bool value) =>
      _prefs.setBool(_keyBatch, value);
}
