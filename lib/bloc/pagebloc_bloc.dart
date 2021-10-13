import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'pagebloc_event.dart';
part 'pagebloc_state.dart';

class PageblocBloc extends Bloc<PageblocEvent, PageblocState> {
  PageblocBloc() : super(PageblocInitial());

  @override
  Stream<PageblocState> mapEventToState(
    PageblocEvent event,
  ) async* {
    if (event is PageFirstEvent) {
      yield PageFirstState();
    }
    if (event is PageSecondEvent) {
      yield PageSecondState();
    }
  }
}
