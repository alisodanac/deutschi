import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/word.dart';
import '../manager/add_word_cubit.dart';

class AddWordFormHelper extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController wordController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController pluralController = TextEditingController();
  final TextEditingController perfectController = TextEditingController();
  final TextEditingController preteritController = TextEditingController();
  final List<TextEditingController> sentenceControllers = [];

  String? _selectedArticle;
  String? _selectedType;
  File? _bwImage;
  File? _colorImage;

  final ImagePicker _picker = ImagePicker();

  String? get selectedArticle => _selectedArticle;
  String? get selectedType => _selectedType;
  File? get bwImage => _bwImage;
  File? get colorImage => _colorImage;

  void setType(String? value) {
    if (_selectedType != value) {
      _selectedType = value;
      notifyListeners();
    }
  }

  void setArticle(String? value) {
    if (_selectedArticle != value) {
      _selectedArticle = value;
      notifyListeners();
    }
  }

  void addSentence() {
    sentenceControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeSentence(int index) {
    sentenceControllers[index].dispose();
    sentenceControllers.removeAt(index);
    notifyListeners();
  }

  Future<void> pickImage(bool isColor) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (isColor) {
        _colorImage = File(image.path);
      } else {
        _bwImage = File(image.path);
      }
      notifyListeners();
    }
  }

  void submit(BuildContext context) {
    if (formKey.currentState!.validate()) {
      final word = Word(
        word: wordController.text,
        article: _selectedType == 'Noun' ? _selectedArticle : null,
        type: _selectedType,
        category: categoryController.text.isNotEmpty ? categoryController.text : null,
        bwImagePath: _bwImage?.path,
        colorImagePath: _colorImage?.path,
        plural: _selectedType == 'Noun' ? pluralController.text : null,
        perfect: _selectedType == 'Verb' ? perfectController.text : null,
        preterit: _selectedType == 'Verb' ? preteritController.text : null,
      );

      final sentences = sentenceControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();

      context.read<AddWordCubit>().addWord(word, sentences);
    }
  }

  void reset() {
    wordController.clear();
    categoryController.clear();
    pluralController.clear();
    perfectController.clear();
    preteritController.clear();
    _selectedArticle = null;
    _selectedType = null;
    _bwImage = null;
    _colorImage = null;
    for (var c in sentenceControllers) {
      c.dispose();
    }
    sentenceControllers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    wordController.dispose();
    categoryController.dispose();
    pluralController.dispose();
    perfectController.dispose();
    preteritController.dispose();
    for (var c in sentenceControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
