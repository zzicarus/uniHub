import 'tag_codec.dart';
import 'tag_models.dart';

/// Pure functions for tag filtering logic independent of any data source.
///
/// All filter operations return new sets — the caller is responsible for
/// persisting state (e.g. via a Riverpod `StateProvider` or similar).
abstract final class TagFilterLogic {
  /// Toggle a tag in the current filter set.
  ///
  /// If [tag] is already present it is removed; otherwise it is added.
  /// Returns the original set unchanged when [tag] normalizes to empty.
  static Set<String> toggle(Set<String> current, String tag) {
    final normalized = TagCodec.normalize(tag);
    if (normalized.isEmpty) return current;
    final next = Set<String>.from(current);
    if (!next.remove(normalized)) {
      next.add(normalized);
    }
    return next;
  }

  /// Remove [tag] from the current filter set.
  ///
  /// Returns the original set unchanged when [tag] normalizes to empty.
  static Set<String> remove(Set<String> current, String tag) {
    final normalized = TagCodec.normalize(tag);
    if (normalized.isEmpty) return current;
    final next = Set<String>.from(current);
    next.remove(normalized);
    return next;
  }

  /// Replace [oldTag] with [newTag] in the filter set.
  ///
  /// If [oldTag] is present it is removed and [newTag] is added.
  /// Returns the original set unchanged if either normalizes to empty.
  static Set<String> rename(
    Set<String> current,
    String oldTag,
    String newTag,
  ) {
    final normalizedOld = TagCodec.normalize(oldTag);
    final normalizedNew = TagCodec.normalize(newTag);
    if (normalizedOld.isEmpty || normalizedNew.isEmpty) return current;
    final next = Set<String>.from(current);
    if (next.remove(normalizedOld)) {
      next.add(normalizedNew);
    }
    return next;
  }

  /// Return an empty filter set (clear all selections).
  static Set<String> clear() => const <String>{};

  /// Check whether [itemTags] match the [selectedTags] under the given [mode].
  ///
  /// * [TagMatchMode.all] — the item must contain **every** selected tag.
  /// * [TagMatchMode.any] — the item must contain **at least one** selected tag.
  ///
  /// Returns `true` when [selectedTags] is empty (no filter active).
  static bool matches({
    required Iterable<String> itemTags,
    required Set<String> selectedTags,
    TagMatchMode mode = TagMatchMode.all,
  }) {
    if (selectedTags.isEmpty) return true;
    final normalizedItemTags = itemTags
        .map(TagCodec.normalize)
        .where((t) => t.isNotEmpty)
        .toSet();
    if (normalizedItemTags.isEmpty) return false;
    return switch (mode) {
      TagMatchMode.any => selectedTags.any(normalizedItemTags.contains),
      TagMatchMode.all => selectedTags.every(normalizedItemTags.contains),
    };
  }

  /// Count the occurrences of each tag across multiple tag lists.
  ///
  /// Returns a map of normalized tag → total count.
  static Map<String, int> countTags(Iterable<Iterable<String>> tagLists) {
    final counts = <String, int>{};
    for (final tags in tagLists) {
      for (final tag in tags) {
        final normalized = TagCodec.normalize(tag);
        if (normalized.isNotEmpty) {
          counts[normalized] = (counts[normalized] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// Sort tag statistics by count (descending) then name (ascending).
  static List<AppTagStat> sortStats(Map<String, int> counts) {
    final entries = counts.entries.toList()..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });
    return entries
        .map((e) => AppTagStat(name: e.key, count: e.value))
        .toList();
  }
}
