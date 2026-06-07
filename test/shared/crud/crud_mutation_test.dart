import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_hub/src/shared/crud/crud.dart';

void main() {
  test('crudMutationProvider increments revision and stores latest event', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const event = CrudMutationEvent(
      type: CrudMutationType.created,
      entityType: CrudEntityType.thought,
      entityId: 1,
      reason: 'test',
    );

    expect(container.read(crudMutationProvider).revision, 0);

    container.read(crudMutationProvider.notifier).emit(event);

    final state = container.read(crudMutationProvider);
    expect(state.revision, 1);
    expect(state.event, same(event));
  });
}
