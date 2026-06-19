@Tags(['acceptance'])
library;

import 'dart:math';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/producer_creation_request.dart';
import 'package:amap_en_ligne/domain/model/producer_request_response.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_bloc.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_event.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_state.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_bloc.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_event.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'producer request creation then owner approval stays coherent',
    () async {
      final publicApi = _ScriptedPublicApi([
        const ProducerRequestResponse(
          requestId: 'req-1',
          status: 'PENDING_VALIDATION',
        ),
      ]);

      final creationBloc = ProducerRequestBloc(publicApi: publicApi);
      final successFuture = creationBloc.stream
          .where((s) => s is ProducerRequestSuccess)
          .cast<ProducerRequestSuccess>()
          .first;

      creationBloc.add(
        const ProducerRequestSubmitted(
          producerName: 'Ferme des Collines',
          adminFirstName: 'Alice',
          adminLastName: 'Martin',
          adminEmail: 'alice@collines.fr',
        ),
      );

      final success = await successFuture;
      expect(success.response.requestId, 'req-1');
      await creationBloc.close();
      publicApi.assertDrained();

      final db = AppDatabase(NativeDatabase.memory());
      final repo = ProducerRequestRepository(
        db: db,
        idGenerator: IdGenerator(Random(0)),
      );
      await db.upsertProducerRequest(
        const AdminProducerRequest(
          requestId: 'req-1',
          producerName: 'Ferme des Collines',
          adminFirstName: 'Alice',
          adminLastName: 'Martin',
          adminEmail: 'alice@collines.fr',
          status: ProducerRequestStatus.pendingValidation,
          submittedAt: '2026-05-07T10:00:00Z',
        ),
      );

      final reviewBloc = ProducerRequestsBloc(producerRequestRepository: repo);
      final loadedFuture = reviewBloc.stream
          .where((s) => s is ProducerRequestsLoaded)
          .cast<ProducerRequestsLoaded>()
          .first;
      reviewBloc.add(const ProducerRequestsEvent.loadRequested());
      final loaded = await loadedFuture;
      expect(
        loaded.requests.single.status,
        ProducerRequestStatus.pendingValidation,
      );

      final approvedFuture = reviewBloc.stream
          .where((s) => s is ProducerRequestsLoaded)
          .cast<ProducerRequestsLoaded>()
          .where(
            (s) => s.requests.single.status == ProducerRequestStatus.approved,
          )
          .first;
      reviewBloc.add(
        ProducerRequestsEvent.approveRequested(request: loaded.requests.single),
      );
      await approvedFuture;

      final pendingMutations = await db.readPendingMutations();
      expect(pendingMutations.length, 1);

      await reviewBloc.close();
      await db.close();
    },
  );
}

class _ScriptedPublicApi extends PublicApi {
  _ScriptedPublicApi(Iterable<ProducerRequestResponse> responses)
    : _responses = responses.toList(),
      super(Dio());

  final List<ProducerRequestResponse> _responses;

  @override
  Future<ProducerRequestResponse> createProducerRequest(
    ProducerCreationRequest request,
  ) async {
    expect(
      _responses,
      isNotEmpty,
      reason: 'Unexpected createProducerRequest call',
    );
    return _responses.removeAt(0);
  }

  void assertDrained() {
    expect(_responses, isEmpty);
  }
}
