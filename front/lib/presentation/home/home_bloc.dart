import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/presentation/home/home_event.dart';
import 'package:amap_en_ligne/presentation/home/home_state.dart';
import 'package:bloc/bloc.dart';

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
    } catch (_) {
      emit(const HomeState.error('Unable to load organizations.'));
    }
  }
}
