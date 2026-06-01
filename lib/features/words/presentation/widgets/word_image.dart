import 'package:flutter/material.dart';

import '../../../../core/constants.dart';

/// Renders a word image in one of two derived looks from a single source image:
/// - B&W (grayscale) used as the learning prompt.
/// - Article-tinted (Der=blue, Das=yellow, Die=pink) used as the colored reveal.
///
/// Both looks are derived at display time, so a word only needs one stored image.
class WordImage extends StatelessWidget {
  final ImageProvider image;
  final String? article;
  final bool colored;
  final double? height;
  final BoxFit fit;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageFrameBuilder? frameBuilder;

  const WordImage({
    super.key,
    required this.image,
    this.article,
    this.colored = false,
    this.height,
    this.fit = BoxFit.cover,
    this.gaplessPlayback = false,
    this.errorBuilder,
    this.frameBuilder,
  });

  // Luminance-weighted grayscale conversion matrix.
  static const List<double> _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    Widget result = Image(
      image: image,
      height: height,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
      frameBuilder: frameBuilder,
    );

    result = ColorFiltered(
      colorFilter: const ColorFilter.matrix(_grayscale),
      child: result,
    );

    if (colored) {
      // Multiply the grayscale image by the article color to get a duotone tint.
      result = ColorFiltered(
        colorFilter: ColorFilter.mode(AppColors.getArticleColor(article), BlendMode.modulate),
        child: result,
      );
    }

    return result;
  }
}
