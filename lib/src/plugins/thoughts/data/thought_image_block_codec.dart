/// Codec for extracting, creating, and removing image blocks in AppFlowy
/// documents.
///
/// Uses AppFlowy's built-in [imageNode] and [ImageBlockKeys] schema.
/// The `url` attribute stores the local file path. A custom `image_id`
/// attribute is added to each image node for reliable identification
/// during removal.
///
/// This is a pure data-layer utility. It works with raw document JSON maps
/// (for persistence) and AppFlowy [Node] objects (for editor operations).
library;

import 'dart:convert';
import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart'
    show ImageBlockKeys, Node, imageNode;

// ---------------------------------------------------------------------------
// ThoughtImageRef
// ---------------------------------------------------------------------------

/// A reference to an image within an AppFlowy document.
class ThoughtImageRef {
  /// Unique business ID for this image reference.
  final String id;

  /// Local file path of the image (also stored as the AppFlowy `url`).
  final String path;

  const ThoughtImageRef({
    required this.id,
    required this.path,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThoughtImageRef && id == other.id && path == other.path;

  @override
  int get hashCode => Object.hash(id, path);

  @override
  String toString() => 'ThoughtImageRef(id: $id, path: $path)';
}

// ---------------------------------------------------------------------------
// ThoughtImageBlockCodec
// ---------------------------------------------------------------------------

abstract final class ThoughtImageBlockCodec {
  /// Custom attribute key for storing an image block's business ID.
  ///
  /// Stored alongside AppFlowy's standard attributes (`url`, `align`, etc.)
  /// so that we can identify and remove specific image blocks.
  static const String imageIdKey = 'image_id';

  static final Random _random = Random();

  // -------------------------------------------------------------------------
  // Node factory
  // -------------------------------------------------------------------------

  /// Creates an [Node] suitable for insertion into an AppFlowy document.
  ///
  /// Uses AppFlowy's built-in [imageNode] with [path] as the `url`
  /// attribute. The [id] is stored as a custom attribute ([imageIdKey])
  /// so that the node can be located later for removal.
  static Node createImageNode({
    required String id,
    required String path,
  }) {
    final node = imageNode(url: path);
    // NOTE: Node.attributes returns a copy of the internal map.
    // Use updateAttributes() to actually persist the custom attribute.
    node.updateAttributes({imageIdKey: id});
    return node;
  }

  /// Generates a unique image ID string.
  ///
  /// Format: `img_<timestamp>_<random>`.
  static String generateImageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'img_${timestamp}_$random';
  }

  // -------------------------------------------------------------------------
  // Extraction (document JSON → List<ThoughtImageRef>)
  // -------------------------------------------------------------------------

  /// Extracts all image references from an AppFlowy document JSON map.
  ///
  /// Walks the document tree recursively, finds all nodes with
  /// `type: 'image'`, and returns a list of [ThoughtImageRef].
  /// Returns an empty list when no image nodes exist.
  static List<ThoughtImageRef> extractImageRefs(
    Map<String, dynamic> document,
  ) {
    final refs = <ThoughtImageRef>[];
    final root = _unwrapDocument(document);
    if (root != null) {
      _collectImageRefs(root, refs);
    }
    return refs;
  }

  // -------------------------------------------------------------------------
  // Removal (document JSON → modified document JSON)
  // -------------------------------------------------------------------------

  /// Removes the image node identified by [imageId] from the document.
  ///
  /// Returns a **new** document map with the specified node removed.
  /// If no matching node is found, the document is returned unchanged.
  static Map<String, dynamic> removeImageNode({
    required Map<String, dynamic> document,
    required String imageId,
  }) {
    // Deep-copy via JSON round-trip so original is never mutated.
    // This is necessary because Map<String, dynamic>.from() only does a
    // shallow copy — nested maps/lists would still be shared references.
    final mutable = jsonDecode(jsonEncode(document)) as Map<String, dynamic>;
    final root = _unwrapDocument(mutable);
    if (root != null) {
      _removeImageNode(root, imageId);
    }
    return mutable;
  }

  // -------------------------------------------------------------------------
  // Presence check
  // -------------------------------------------------------------------------

  /// Returns `true` if any image node in the document references [path].
  static bool containsPath(
    Map<String, dynamic> document,
    String path,
  ) {
    final refs = extractImageRefs(document);
    return refs.any((r) => r.path == path);
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Unwraps the outer `{'document': {...}}` wrapper if present.
  ///
  /// AppFlowy's [Document.toJson] produces:
  /// ```json
  /// { "document": { "type": "page", "children": [...] } }
  /// ```
  /// Returns the inner root node map.
  static Map<String, dynamic>? _unwrapDocument(Map<String, dynamic> json) {
    if (json.containsKey('document')) {
      final doc = json['document'];
      if (doc is Map<String, dynamic>) return doc;
    }
    // Already unwrapped or malformed — return as-is.
    if (json['type'] == 'page' || json.containsKey('children')) return json;
    return null;
  }

  /// Recursively collects [ThoughtImageRef] from all image nodes.
  static void _collectImageRefs(
    Map<String, dynamic> node,
    List<ThoughtImageRef> refs,
  ) {
    if (node['type'] == 'image') {
      final attributes = node['attributes'] as Map<String, dynamic>?;
      if (attributes != null) {
        final url = attributes[ImageBlockKeys.url] as String?;
        if (url != null && url.isNotEmpty) {
          final imageId = attributes[imageIdKey] as String? ?? '';
          refs.add(ThoughtImageRef(id: imageId, path: url));
        }
      }
    }

    final children = node['children'] as List<dynamic>?;
    if (children != null) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          _collectImageRefs(child, refs);
        }
      }
    }
  }

  /// Recursively removes the first image node whose [imageIdKey] matches.
  ///
  /// Returns `true` if a node was removed. Walks bottom-up so nested
  /// structures (e.g. columns inside page) are handled correctly.
  static bool _removeImageNode(
    Map<String, dynamic> node,
    String imageId,
  ) {
    final children = node['children'] as List<dynamic>?;
    if (children == null || children.isEmpty) return false;

    // Iterate in reverse so removal doesn't shift indices.
    for (int i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      if (child is Map<String, dynamic>) {
        if (_isImageNodeWithId(child, imageId)) {
          children.removeAt(i);
          return true;
        }
        // Recurse into nested children.
        if (_removeImageNode(child, imageId)) return true;
      }
    }
    return false;
  }

  /// Checks whether [node] is an image node with the given [imageId].
  static bool _isImageNodeWithId(
    Map<String, dynamic> node,
    String imageId,
  ) {
    if (node['type'] != 'image') return false;
    final attributes = node['attributes'] as Map<String, dynamic>?;
    if (attributes == null) return false;
    return attributes[imageIdKey] == imageId;
  }
}
