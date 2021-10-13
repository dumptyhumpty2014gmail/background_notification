part of 'pagebloc_bloc.dart';

@immutable
abstract class PageblocEvent {}

class PageFirstEvent extends PageblocEvent {}

class PageSecondEvent extends PageblocEvent {}
