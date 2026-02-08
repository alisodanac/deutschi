import 'package:flutter/material.dart';
import '../helpers/add_word_form_helper.dart';

class ImagePickerSection extends StatelessWidget {
  final AddWordFormHelper helper;

  const ImagePickerSection({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildImagePicker(context, 'BW Image', false),
        const SizedBox(width: 16),
        _buildImagePicker(context, 'Color Image', true),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context, String label, bool isColor) {
    final imageFile = isColor ? helper.colorImage : helper.bwImage;
    return Expanded(
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => helper.pickImage(isColor),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageFile != null
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
