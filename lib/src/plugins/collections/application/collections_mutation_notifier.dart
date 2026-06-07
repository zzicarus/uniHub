import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collections_mutation_event.dart';

/// Immutable snapshot of the mutation state.
///
/// Each mutation bumps [revision] so listeners can cheaply detect changes.
/// The [event] field carries the most recent mutation for downstream
/// controllers that need to react to specific event types.
class CollectionsMutationState {
  const CollectionsMutationState({
    required this.revision,
    this.event,
  });

  /// Monotonically increasing revision counter.
  final int revision;

  /// The most recent mutation event, or null at initial state.
  final CollectionsMutationEvent? event;

  CollectionsMutationState next(CollectionsMutationEvent event) {
    return CollectionsMutationState(
      revision: revision + 1,
      event: event,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionsMutationState && revision == other.revision;

  @override
  int get hashCode => revision.hashCode;
}

/// Notifier that emits mutation events as they happen.
///
/// Downstream controllers (CollectionsListController, detail providers)
/// listen to this stream to apply precise patches rather than full reloads.
class CollectionsMutationNotifier
    extends StateNotifier<CollectionsMutationState> {
  CollectionsMutationNotifier()
      : super(const CollectionsMutationState(revision: 0));

  void emit(CollectionsMutationEvent event) {
    state = state.next(event);
  }
}
