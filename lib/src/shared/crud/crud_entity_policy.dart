enum CrudEntityType {
  thought,
  savedItem,
  collectionBox,
  tag,
  note,
  todo,
  calendarEvent,
  attachment,
  themeProject,
  storageItem,
}

enum NameUniqueScope { none, global, parent, workspace, plugin }

class CrudEntityPolicy {
  const CrudEntityPolicy({
    required this.entityType,
    this.nameUniqueScope = NameUniqueScope.none,
    this.supportsSoftDelete = false,
    this.supportsUndo = false,
    this.requiresDeleteConfirm = false,
    this.supportsMerge = false,
    this.maxNameLength,
  });

  final CrudEntityType entityType;
  final NameUniqueScope nameUniqueScope;
  final bool supportsSoftDelete;
  final bool supportsUndo;
  final bool requiresDeleteConfirm;
  final bool supportsMerge;
  final int? maxNameLength;

  static const savedItem = CrudEntityPolicy(
    entityType: CrudEntityType.savedItem,
    supportsUndo: true,
    requiresDeleteConfirm: true,
  );

  static const thought = CrudEntityPolicy(
    entityType: CrudEntityType.thought,
    supportsSoftDelete: true,
    supportsUndo: true,
  );

  static const collectionBox = CrudEntityPolicy(
    entityType: CrudEntityType.collectionBox,
    nameUniqueScope: NameUniqueScope.parent,
    supportsUndo: true,
    requiresDeleteConfirm: true,
    maxNameLength: 30,
  );

  static const tag = CrudEntityPolicy(
    entityType: CrudEntityType.tag,
    nameUniqueScope: NameUniqueScope.global,
    supportsUndo: true,
    requiresDeleteConfirm: true,
    supportsMerge: true,
    maxNameLength: 24,
  );

  static CrudEntityPolicy defaultsFor(CrudEntityType type) {
    return switch (type) {
      CrudEntityType.savedItem => savedItem,
      CrudEntityType.thought => thought,
      CrudEntityType.collectionBox => collectionBox,
      CrudEntityType.tag => tag,
      CrudEntityType.note => const CrudEntityPolicy(
        entityType: CrudEntityType.note,
        nameUniqueScope: NameUniqueScope.parent,
        supportsSoftDelete: true,
        supportsUndo: true,
      ),
      CrudEntityType.todo => const CrudEntityPolicy(
        entityType: CrudEntityType.todo,
        supportsSoftDelete: true,
        supportsUndo: true,
      ),
      CrudEntityType.calendarEvent => const CrudEntityPolicy(
        entityType: CrudEntityType.calendarEvent,
        supportsSoftDelete: true,
        supportsUndo: true,
      ),
      CrudEntityType.attachment => const CrudEntityPolicy(
        entityType: CrudEntityType.attachment,
        requiresDeleteConfirm: true,
      ),
      CrudEntityType.themeProject => const CrudEntityPolicy(
        entityType: CrudEntityType.themeProject,
        nameUniqueScope: NameUniqueScope.global,
        maxNameLength: 30,
      ),
      CrudEntityType.storageItem => const CrudEntityPolicy(
        entityType: CrudEntityType.storageItem,
        requiresDeleteConfirm: true,
      ),
    };
  }
}
