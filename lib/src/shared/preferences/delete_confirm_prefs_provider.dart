import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'delete_confirm_prefs.dart';

/// Asynchronously initializes [SharedPreferences] and creates [DeleteConfirmPrefs].
final deleteConfirmPrefsProvider =
    FutureProvider<DeleteConfirmPrefs>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return DeleteConfirmPrefs(prefs);
});
