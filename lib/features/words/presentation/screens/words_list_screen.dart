import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../manager/words_list_cubit.dart';
import '../manager/words_list_state.dart';

class WordsListScreen extends StatelessWidget {
  const WordsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => sl<WordsListCubit>()..loadCategories(), child: const WordsListView());
  }
}

class WordsListView extends StatelessWidget {
  const WordsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: BlocBuilder<WordsListCubit, WordsListState>(
        builder: (context, state) {
          if (state is WordsListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WordsListSuccess) {
            if (state.categories.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No categories yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Add a word to create a category', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(category),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.push('/category/$category');
                    },
                  ),
                );
              },
            );
          } else if (state is WordsListFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/add_word');
          // Refresh list when coming back
          if (context.mounted) {
            context.read<WordsListCubit>().loadCategories();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
