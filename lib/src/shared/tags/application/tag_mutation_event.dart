/// Events emitted by the tag mutation pipeline so that affected UI
/// components can patch themselves without a full page reload.
sealed class TagMutationEvent {
  const TagMutationEvent();
}

class TagCreated extends TagMutationEvent {
  const TagCreated(this.tagId);
  final int tagId;
}

class TagUpdated extends TagMutationEvent {
  const TagUpdated(this.tagId);
  final int tagId;
}

class TagDeleted extends TagMutationEvent {
  const TagDeleted(this.tagId);
  final int tagId;
}

class TagAddedToThought extends TagMutationEvent {
  const TagAddedToThought({
    required this.thoughtId,
    required this.tagId,
  });

  final int thoughtId;
  final int tagId;
}

class TagRemovedFromThought extends TagMutationEvent {
  const TagRemovedFromThought({
    required this.thoughtId,
    required this.tagId,
  });

  final int thoughtId;
  final int tagId;
}

class TagAddedToSavedItem extends TagMutationEvent {
  const TagAddedToSavedItem({
    required this.savedItemId,
    required this.tagId,
  });

  final int savedItemId;
  final int tagId;
}

class TagRemovedFromSavedItem extends TagMutationEvent {
  const TagRemovedFromSavedItem({
    required this.savedItemId,
    required this.tagId,
  });

  final int savedItemId;
  final int tagId;
}

class TagMerged extends TagMutationEvent {
  const TagMerged({
    required this.sourceTagId,
    required this.targetTagId,
  });

  final int sourceTagId;
  final int targetTagId;
}
