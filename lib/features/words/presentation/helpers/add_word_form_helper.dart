import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/gemini_service.dart';
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
  File? _image;
  // True when [_image] is an AI-generated image already colored in the article
  // color, so it is stored as the color image and the B&W look is derived from it.
  bool _imageIsColored = false;
  // Original hand-made color image of an existing word, preserved on edit unless
  // the user picks a new single image.
  String? _existingColorImagePath;

  final ImagePicker _picker = ImagePicker();

  String? get selectedArticle => _selectedArticle;
  WordType? get selectedType => _selectedType;
  File? get image => _image;
  bool get imageIsColored => _imageIsColored;

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

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _image = File(image.path);
      // A manually picked image is a plain source: derive B&W + tint from it.
      _imageIsColored = false;
      // A newly picked image supersedes any old hand-made color image.
      _existingColorImagePath = null;
      notifyListeners();
    }
  }

  void applyAiSuggestion(WordSuggestion s, {String? imagePath, bool imageIsColored = false}) {
    if (s.type != null) _selectedType = s.type;

    if (imagePath != null) {
      _image = File(imagePath);
      _imageIsColored = imageIsColored;
      _existingColorImagePath = null;
    }

    if (_selectedType == WordType.noun) {
      if (s.article != null) _selectedArticle = s.article;
      if (s.plural != null) pluralController.text = s.plural!;
    } else if (_selectedType == WordType.verb) {
      if (s.perfect != null) perfectController.text = s.perfect!;
      if (s.preterit != null) preteritController.text = s.preterit!;
    }

    if (s.category != null) categoryController.text = s.category!;

    if (s.sentences.isNotEmpty) {
      for (final c in sentenceControllers) {
        c.dispose();
      }
      sentenceControllers.clear();
      for (final sentence in s.sentences.take(4)) {
        sentenceControllers.add(TextEditingController(text: sentence));
      }
    }

    notifyListeners();
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
    final sourcePath = word.bwImagePath ?? word.colorImagePath;
    _image = sourcePath != null ? File(sourcePath) : null;
    // A word with only a color image (AI-generated or legacy) is treated as colored.
    _imageIsColored = word.bwImagePath == null && word.colorImagePath != null;
    _existingColorImagePath = word.colorImagePath;

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
        bwImagePath: _imageIsColored ? null : _image?.path,
        colorImagePath: _imageIsColored ? _image?.path : _existingColorImagePath,
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
    _image = null;
    _imageIsColored = false;
    _existingColorImagePath = null;
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
