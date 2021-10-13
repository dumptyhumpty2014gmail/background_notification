part of 'pagebloc_bloc.dart';

@immutable
abstract class PageblocState {}

class PageblocInitial extends PageblocState {}

class PageFirstState extends PageblocState {}

class PageSecondState extends PageblocState {}
