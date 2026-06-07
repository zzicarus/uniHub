import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crud_entity_policy.dart';

enum CrudMutationType { created, changed, deleted, restored, merged }

class CrudMutationEvent {
  const CrudMutationEvent({
    required this.type,
    required this.entityType,
    required this.entityId,
    this.previousEntityId,
    this.reason,
  });

  final CrudMutationType type;
  final CrudEntityType entityType;
  final Object entityId;
  final Object? previousEntityId;
  final String? reason;
}

class CrudMutationState {
  const CrudMutationState({required this.revision, this.event});

  final int revision;
  final CrudMutationEvent? event;

  CrudMutationState next(CrudMutationEvent event) {
    return CrudMutationState(revision: revision + 1, event: event);
  }
}

class CrudMutationNotifier extends StateNotifier<CrudMutationState> {
  CrudMutationNotifier() : super(const CrudMutationState(revision: 0));

  void emit(CrudMutationEvent event) {
    state = state.next(event);
  }
}

final crudMutationProvider =
    StateNotifierProvider<CrudMutationNotifier, CrudMutationState>((ref) {
      return CrudMutationNotifier();
    });
