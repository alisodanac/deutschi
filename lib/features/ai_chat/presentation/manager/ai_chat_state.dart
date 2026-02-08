import 'package:equatable/equatable.dart';

enum MessageRole { user, model }

class ChatMessage extends Equatable {
  final String text;
  final MessageRole role;

  const ChatMessage({required this.text, required this.role});

  @override
  List<Object?> get props => [text, role];
}

class AIChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? apiKey; // To verify if we have one

  const AIChatState({this.messages = const [], this.isLoading = false, this.error, this.apiKey});

  AIChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error, String? apiKey}) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // If new error passed, replace. If null, keep null? Or reset? Usually reset if successful. Let's make it clearer.
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, apiKey];
}
