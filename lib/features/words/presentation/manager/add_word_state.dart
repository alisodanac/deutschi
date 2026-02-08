import 'package:equatable/equatable.dart';

abstract class AddWordState extends Equatable {
  const AddWordState();

  @override
  List<Object?> get props => [];
}

class AddWordInitial extends AddWordState {}

class AddWordLoading extends AddWordState {}

class AddWordLoaded extends AddWordState {
  final List<String> categories;

  const AddWordLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AddWordSuccess extends AddWordState {}

class AddWordFailure extends AddWordState {
  final String message;

  const AddWordFailure(this.message);

  @override
  List<Object?> get props => [message];
}
