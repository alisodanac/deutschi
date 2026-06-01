import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/image_search_service.dart';
import 'ai_fill_state.dart';

class AiFillCubit extends Cubit<AiFillState> {
  final GeminiService geminiService;
  final ImageSearchService imageSearchService;

  AiFillCubit(this.geminiService, this.imageSearchService) : super(AiFillInitial());

  Future<void> generate(String word, {List<String> existingCategories = const []}) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      emit(const AiFillFailure('Enter a word first.'));
      return;
    }

    emit(AiFillLoading());
    try {
      final suggestion = await geminiService.generateWord(trimmed, existingCategories: existingCategories);
      final query = suggestion.imageQuery ?? trimmed;
      final colorName = AppColors.getArticleColorName(suggestion.article);

      // Prefer an AI-generated image colored in the article color. If generation
      // fails (e.g. service busy), fall back to a stock image search.
      final generated = await imageSearchService.generateImage(query, colorName: colorName);
      if (generated != null) {
        emit(AiFillSuccess(suggestion, imagePath: generated, imageIsColored: colorName != null));
        return;
      }

      final fetched = await imageSearchService.fetchAndSaveImage(query);
      emit(AiFillSuccess(suggestion, imagePath: fetched, imageIsColored: false));
    } catch (e) {
      emit(AiFillFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
