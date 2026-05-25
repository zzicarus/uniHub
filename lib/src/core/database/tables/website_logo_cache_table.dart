import 'package:drift/drift.dart';

/// Cached website logos for site-level reuse.
///
/// Each row represents one site (by [siteKey]). The actual logo image is
/// stored as a local file pointed to by [localLogoPath]. UI reads from
/// this table; background enrichment jobs populate it.
class WebsiteLogoCacheTable extends Table {
  @override
  String get tableName => 'website_logo_cache';

  IntColumn get id => integer().autoIncrement()();

  /// Normalised site key, e.g. "bilibili.com", "chatgpt.com".
  TextColumn get siteKey => text().unique()();

  /// Original host, e.g. "www.bilibili.com".
  TextColumn get host => text()();

  /// Remote favicon URL declared by the page (may be null).
  TextColumn get remoteLogoUrl => text().nullable()();

  /// Local file path to the cached logo image.
  TextColumn get localLogoPath => text().nullable()();

  /// MIME type of the cached image, e.g. "image/png", "image/x-icon".
  TextColumn get mimeType => text().nullable()();

  /// success / pending / failed.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Last error message when fetching failed.
  TextColumn get lastError => text().nullable()();

  /// Timestamp of the last successful fetch.
  DateTimeColumn get fetchedAt => dateTime().nullable()();

  /// TTL: entries past this time should be refreshed.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
