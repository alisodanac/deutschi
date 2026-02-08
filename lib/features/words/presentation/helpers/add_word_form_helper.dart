import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/word.dart';
import '../../domain/entities/word_type.dart';
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
  WordType? _selectedType;
  File? _bwImage;
  File? _colorImage;

  final ImagePicker _picker = ImagePicker();

  String? get selectedArticle => _selectedArticle;
  WordType? get selectedType => _selectedType;
  File? get bwImage => _bwImage;
  File? get colorImage => _colorImage;

  void setType(WordType? value) {
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

  int? _editingWordId;
  int? get editingWordId => _editingWordId;

  void initialize(Word word, List<String> sentences) {
    _editingWordId = word.id;
    wordController.text = word.word;
    categoryController.text = word.category ?? '';
    pluralController.text = word.plural ?? '';
    perfectController.text = word.perfect ?? '';
    preteritController.text = word.preterit ?? '';
    _selectedArticle = word.article;
    _selectedType = word.type;
    _bwImage = word.bwImagePath != null ? File(word.bwImagePath!) : null;
    _colorImage = word.colorImagePath != null ? File(word.colorImagePath!) : null;

    sentenceControllers.clear();
    for (var s in sentences) {
      sentenceControllers.add(TextEditingController(text: s));
    }
    notifyListeners();
  }

  void submit(BuildContext context) {
    if (formKey.currentState!.validate()) {
      final word = Word(
        id: _editingWordId,
        word: wordController.text,
        article: _selectedType == WordType.noun ? _selectedArticle : null,
        type: _selectedType,
        category: categoryController.text.isNotEmpty ? categoryController.text : null,
        bwImagePath: _bwImage?.path,
        colorImagePath: _colorImage?.path,
        plural: _selectedType == WordType.noun ? pluralController.text : null,
        perfect: _selectedType == WordType.verb ? perfectController.text : null,
        preterit: _selectedType == WordType.verb ? preteritController.text : null,
      );

      final sentences = sentenceControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList();

      if (_editingWordId != null) {
        context.read<AddWordCubit>().updateWord(word, sentences);
      } else {
        context.read<AddWordCubit>().addWord(word, sentences);
      }
    }
  }

  void reset() {
    _editingWordId = null;
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
