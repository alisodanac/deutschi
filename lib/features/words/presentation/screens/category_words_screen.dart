import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants.dart';
import '../manager/category_words_cubit.dart';
import '../manager/category_words_state.dart';

class CategoryWordsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryWordsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CategoryWordsCubit>()..loadWords(categoryName),
      child: Scaffold(
        appBar: AppBar(title: Text(categoryName)),
        body: BlocBuilder<CategoryWordsCubit, CategoryWordsState>(
          builder: (context, state) {
            if (state is CategoryWordsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoryWordsSuccess) {
              if (state.words.isEmpty) {
                return const Center(child: Text('No words in this category'));
              }
              return ListView.builder(
                itemCount: state.words.length,
                itemBuilder: (context, index) {
                  final word = state.words[index];
                  final articleColor = AppColors.getArticleColor(word.article);
                  final isDas = word.article?.toLowerCase() == 'das';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(word.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(word.type?.toString() ?? ''),
                      leading: word.article != null
                          ? CircleAvatar(
                              backgroundColor: articleColor,
                              child: Text(
                                word.article!,
                                style: TextStyle(
                                  color: isDas ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Icon(Icons.abc),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        context.push('/word_details', extra: word);
                      },
                    ),
                  );
                },
              );
            } else if (state is CategoryWordsFailure) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
