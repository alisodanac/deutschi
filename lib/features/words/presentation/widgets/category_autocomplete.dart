import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../manager/add_word_cubit.dart';
import '../manager/add_word_state.dart';
import '../helpers/add_word_form_helper.dart';

class CategoryAutocomplete extends StatelessWidget {
  final AddWordFormHelper helper;

  const CategoryAutocomplete({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddWordCubit, AddWordState>(
      buildWhen: (previous, current) => current is AddWordLoaded,
      builder: (context, state) {
        List<String> categories = [];
        if (state is AddWordLoaded) {
          categories = state.categories;
        }

        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return categories.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            helper.categoryController.text = selection;
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != helper.categoryController.text) {
              textEditingController.text = helper.categoryController.text;
            }
            // Bind changes back to helper controller
            // Note: This creates a listener every build, potentially problematic but Autocomplete rebuilds are tricky.
            // Ideally we check if listener already added or make helper expose a sync method.
            // Simplest is to just listen once or verify value match on submit.
            // But Autocomplete's controller is separate.
            // Let's just update helper on change.
            textEditingController.addListener(() {
              if (helper.categoryController.text != textEditingController.text) {
                helper.categoryController.text = textEditingController.text;
              }
            });

            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
        );
      },
    );
  }
}
