import 'package:equatable/equatable.dart';

import '../../../../core/services/gemini_service.dart';

abstract class AiFillState extends Equatable {
  const AiFillState();

  @override
  List<Object?> get props => [];
}

class AiFillInitial extends AiFillState {}

class AiFillLoading extends AiFillState {}

class AiFillSuccess extends AiFillState {
  final WordSuggestion suggestion;
  final String? imagePath;
  // True when [imagePath] is an AI-generated image already colored in the
  // article color (so it should be shown as-is, not re-tinted).
  final bool imageIsColored;

  const AiFillSuccess(this.suggestion, {this.imagePath, this.imageIsColored = false});

  @override
  List<Object?> get props => [suggestion, imagePath, imageIsColored];
}

class AiFillFailure extends AiFillState {
  final String message;

  const AiFillFailure(this.message);

  @override
  List<Object?> get props => [message];
}
