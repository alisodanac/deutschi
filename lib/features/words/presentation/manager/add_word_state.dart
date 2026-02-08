import 'package:equatable/equatable.dart';

abstract class AddWordState extends Equatable {
  const AddWordState();

  @override
  List<Object?> get props => [];
}

class AddWordInitial extends AddWordState {}

class AddWordLoading extends AddWordState {}

class AddWordSuccess extends AddWordState {}

class AddWordFailure extends AddWordState {
  final String message;

  const AddWordFailure(this.message);

  @override
  List<Object?> get props => [message];
}
