import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_chat_state.dart';

class AIChatCubit extends Cubit<AIChatState> {
  // We manage the service lifecycle here for simplicity

  AIChatCubit() : super(const AIChatState());

  // Function to set API Key
  void setApiKey(String key) {
    if (key.isNotEmpty) {
      // Re-initialize service or create it.
      // For now let's just use the google_generative_ai package directly here or in a simple helper function.
      // Or update state.
      emit(state.copyWith(apiKey: key));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, role: MessageRole.user);
    emit(state.copyWith(messages: List.from(state.messages)..add(userMessage), isLoading: true, error: null));

    try {
      if (state.apiKey == null || state.apiKey!.isEmpty) {
        throw Exception("API Key is missing. Please set it in settings.");
      }

      // Initialize model on demand or reuse?
      // Reusing is better. But with simple structure:
      final model = GenerativeModel(model: 'gemini-pro', apiKey: state.apiKey!);
      final content = [Content.text(text)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final aiMessage = ChatMessage(text: response.text!, role: MessageRole.model);
        emit(state.copyWith(messages: List.from(state.messages)..add(aiMessage), isLoading: false));
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
