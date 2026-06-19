import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryTemplateRepository extends Mock
    implements DeliveryTemplateRepository {}

const _orgId = 'org-1';

final _template = DeliveryTemplate(
  deliveryTemplateId: 'dt-1',
  organizationId: _orgId,
  name: 'Livraison standard',
  standardStartTime: '18:00',
  standardEndTime: '20:00',
);

void main() {
  late _MockDeliveryTemplateRepository repo;

  setUpAll(() {
    registerFallbackValue(
      const DeliveryTemplate(
        deliveryTemplateId: 'fallback',
        organizationId: 'fallback',
        name: 'fallback',
        standardStartTime: '00:00',
        standardEndTime: '00:00',
      ),
    );
  });

  setUp(() {
    repo = _MockDeliveryTemplateRepository();
  });

  DeliveryTemplateBloc buildBloc() =>
      DeliveryTemplateBloc(repository: repo, organizationId: _orgId);

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'loadTemplates emits loading then loaded with templates',
    setUp: () => when(
      () => repo.watch(_orgId),
    ).thenAnswer((_) => Stream.value([_template])),
    build: buildBloc,
    act: (bloc) => bloc.add(const DeliveryTemplateEvent.loadTemplates()),
    expect: () => [
      const DeliveryTemplateState.loading(),
      isA<DeliveryTemplateLoaded>().having((s) => s.templates, 'templates', [
        _template,
      ]),
    ],
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'loadTemplates emits loaded with empty list when no templates',
    setUp: () =>
        when(() => repo.watch(_orgId)).thenAnswer((_) => Stream.value([])),
    build: buildBloc,
    act: (bloc) => bloc.add(const DeliveryTemplateEvent.loadTemplates()),
    expect: () => [
      const DeliveryTemplateState.loading(),
      isA<DeliveryTemplateLoaded>().having(
        (s) => s.templates,
        'templates',
        isEmpty,
      ),
    ],
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'createTemplate calls repository.create',
    setUp: () => when(() => repo.create(any())).thenAnswer((invocation) async {
      return invocation.positionalArguments.single as DeliveryTemplate;
    }),
    build: buildBloc,
    act: (bloc) => bloc.add(DeliveryTemplateEvent.createTemplate(_template)),
    verify: (_) {
      verify(() => repo.create(_template)).called(1);
    },
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'createTemplate emits error when repository throws',
    setUp: () =>
        when(() => repo.create(any())).thenThrow(Exception('network error')),
    build: buildBloc,
    act: (bloc) => bloc.add(DeliveryTemplateEvent.createTemplate(_template)),
    expect: () => [isA<DeliveryTemplateError>()],
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'updateTemplate calls repository.update',
    setUp: () => when(() => repo.update(any())).thenAnswer((_) async {}),
    build: buildBloc,
    act: (bloc) => bloc.add(DeliveryTemplateEvent.updateTemplate(_template)),
    verify: (_) {
      verify(() => repo.update(_template)).called(1);
    },
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'updateTemplate emits error when repository throws',
    setUp: () =>
        when(() => repo.update(any())).thenThrow(Exception('network error')),
    build: buildBloc,
    act: (bloc) => bloc.add(DeliveryTemplateEvent.updateTemplate(_template)),
    expect: () => [isA<DeliveryTemplateError>()],
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'deleteTemplate calls repository.delete',
    setUp: () => when(() => repo.delete(any(), any())).thenAnswer((_) async {}),
    build: buildBloc,
    act: (bloc) => bloc.add(
      const DeliveryTemplateEvent.deleteTemplate(
        templateId: 'dt-1',
        organizationId: _orgId,
      ),
    ),
    verify: (_) {
      verify(() => repo.delete('dt-1', _orgId)).called(1);
    },
  );

  blocTest<DeliveryTemplateBloc, DeliveryTemplateState>(
    'deleteTemplate emits error when repository throws',
    setUp: () => when(
      () => repo.delete(any(), any()),
    ).thenThrow(Exception('network error')),
    build: buildBloc,
    act: (bloc) => bloc.add(
      const DeliveryTemplateEvent.deleteTemplate(
        templateId: 'dt-1',
        organizationId: _orgId,
      ),
    ),
    expect: () => [isA<DeliveryTemplateError>()],
  );
}
