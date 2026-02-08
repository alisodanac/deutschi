import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants.dart';
import '../../domain/entities/word.dart';
import '../manager/word_details_cubit.dart';
import '../manager/category_words_cubit.dart';

class WordDetailsScreen extends StatelessWidget {
  final Word word;

  const WordDetailsScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WordDetailsCubit>()..loadSentences(word.id!),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(word.word),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    // Get current sentences
                    final state = context.read<WordDetailsCubit>().state;
                    List<String> sentences = [];
                    if (state is WordDetailsSuccess) {
                      sentences = state.sentences;
                    }

                    final result = await context.push<bool>('/add_word', extra: {'word': word, 'sentences': sentences});

                    if (result == true) {
                      // Reload sentences
                      if (context.mounted) {
                        context.read<WordDetailsCubit>().loadSentences(word.id!);
                        // Also need to refresh word details somehow or pop back?
                        // Since WordDetailsScreen depends on 'word' passed in constructor,
                        // simpler might be to just pop back and let previous screen refresh,
                        // or better, we should probably fetch the word again.
                        // For now let's just refresh sentences and show a message.
                        // Ideally we would have a WordDetailsCubit that loads the Word too.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Word updated. Please go back to refresh details.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Article and Word
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Details Section
                  _buildDetails(context),
                  const SizedBox(height: 24),

                  // Images Section
                  _buildImages(context),
                  const SizedBox(height: 24),

                  // Sentences Section
                  const Text('Sentences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  BlocBuilder<WordDetailsCubit, WordDetailsState>(
                    builder: (context, state) {
                      if (state is WordDetailsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is WordDetailsSuccess) {
                        if (state.sentences.isEmpty) {
                          return const Text('No sentences added.');
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.sentences.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(state.sentences[index], style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          },
                        );
                      } else if (state is WordDetailsFailure) {
                        return Text(
                          'Error loading sentences: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (word.article != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.getArticleColor(word.article), shape: BoxShape.circle),
            child: Text(
              word.article!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: word.article == 'Das' ? Colors.black : Colors.white,
              ),
            ),
          ),
        if (word.article != null) const SizedBox(width: 16),
        Expanded(
          child: Text(word.word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow('Type', word.type?.toString() ?? '-'),
            _buildDetailRow('Category', word.category ?? '-'),
            if (word.plural != null) _buildDetailRow('Plural', word.plural!),
            if (word.perfect != null) _buildDetailRow('Perfect', word.perfect!),
            if (word.preterit != null) _buildDetailRow('Preterit', word.preterit!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    if (word.bwImagePath == null && word.colorImagePath == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('No images added.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (word.bwImagePath != null)
              Expanded(
                child: Column(
                  children: [
                    Image.file(File(word.bwImagePath!), height: 150, fit: BoxFit.cover),
                    const SizedBox(height: 4),
                    const Text('B&W', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            if (word.bwImagePath != null && word.colorImagePath != null) const SizedBox(width: 16),
            if (word.colorImagePath != null)
              Expanded(
                child: Column(
                  children: [
                    Image.file(File(word.colorImagePath!), height: 150, fit: BoxFit.cover),
                    const SizedBox(height: 4),
                    const Text('Color', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
