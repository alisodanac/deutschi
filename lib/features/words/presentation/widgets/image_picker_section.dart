import 'dart:io';

import 'package:flutter/material.dart';

import '../helpers/add_word_form_helper.dart';
import 'word_image.dart';

class ImagePickerSection extends StatelessWidget {
  final AddWordFormHelper helper;

  const ImagePickerSection({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    final imageFile = helper.image;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Auto-fill finds an image for you, or tap to pick one. The B&W and colored versions are derived from it automatically.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: helper.pickImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageFile != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(imageFile, fit: BoxFit.cover))
                : const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
          ),
        ),
        if (imageFile != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPreview('B&W', FileImage(imageFile), colored: false),
              const SizedBox(width: 16),
              _buildColorPreview(imageFile),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildColorPreview(File imageFile) {
    final label = helper.selectedArticle ?? 'Color';
    // An AI-generated image is already colored in the article color — show it
    // as-is rather than applying the tint a second time.
    if (helper.imageIsColored) {
      return Expanded(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(imageFile, height: 90, fit: BoxFit.cover),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    return _buildPreview(label, FileImage(imageFile), colored: true);
  }

  Widget _buildPreview(String label, ImageProvider provider, {required bool colored}) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WordImage(
              image: provider,
              article: helper.selectedArticle,
              colored: colored,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
