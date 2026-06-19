import 'dart:async';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/presentation/home/home_event.dart';
import 'package:amap_en_ligne/presentation/home/home_state.dart';
import 'package:bloc/bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required PublicApi publicApi})
    : _publicApi = publicApi,
      super(const HomeState.initial()) {
    on<HomeLoadRequested>(_onLoadRequested);
    add(const HomeEvent.loadRequested());
  }

  final PublicApi _publicApi;

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeState.loading());
    try {
      final orgs = await _publicApi.listOrganizations();
      emit(HomeState.loaded(organizations: orgs));
    } on Exception catch (e, stackTrace) {
      unawaited(Sentry.captureException(e, stackTrace: stackTrace));
      emit(const HomeState.error('Unable to load organizations.'));
    }
  }
}
