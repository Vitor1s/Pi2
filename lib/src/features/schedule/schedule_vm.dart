import 'package:asyncstate/asyncstate.dart';
import 'package:pi2/src/core/fp/either.dart';
import 'package:pi2/src/core/providers/application_providers.dart';
import 'package:pi2/src/features/schedule/schedule_state.dart';
import 'package:pi2/src/models/barbeariapi_model.dart';
import 'package:pi2/src/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_vm.g.dart';

@riverpod
class ScheduleVM extends _$ScheduleVM {
  @override
  ScheduleState build() => ScheduleState.initial();

  void timeSelect(int hour) {
    if (hour == state.scheduleTime) {
      state = state.copyWith(scheduleHour: () => null);
    } else {
      state = state.copyWith(scheduleHour: () => hour);
    }
  }

  void dateSelect(DateTime date) {
    state = state.copyWith(scheduleDate: () => date);
  }

  Future<void> register({
    required UserModel user,
    required String clientName,
  }) async {
    final asyncLoaderHandler = AsyncLoaderHandler()..start();
    final ScheduleState(:scheduleDate, :scheduleTime) = state;
    final scheduleRepository = ref.read(scheduleRepositoryProvider);
    final BarbeariapiModel(id: barbeariapiId) = await ref.watch(
      getMyBarbeariapiProvider.future,
    );

    final dto = (
      barbeariapiId: barbeariapiId,
      userId: user.id,
      clientName: clientName,
      date: scheduleDate!,
      time: scheduleTime!,
    );

    final scheduleResult = await scheduleRepository.scheduleClient(dto);

    switch (scheduleResult) {
      case Success():
        state = state.copyWith(status: ScheduleStateStatus.success);
      case Failure():
        state = state.copyWith(status: ScheduleStateStatus.error);
    }

    asyncLoaderHandler.close();
  }
}
