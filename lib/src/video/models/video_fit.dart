import 'package:flutter/painting.dart';

class VideoFit {
  final Alignment alignment;

  final double aspectRatio;

  final double sizeFactor;

  const VideoFit({
    this.alignment = Alignment.center,
    this.aspectRatio = -1,
    this.sizeFactor = 1.0,
  });

  static const VideoFit fill = VideoFit(
    sizeFactor: 1.0,
    aspectRatio: double.infinity,
    alignment: Alignment.center,
  );

  static const VideoFit contain = VideoFit(
    sizeFactor: 1.0,
    aspectRatio: -1,
    alignment: Alignment.center,
  );

  static const VideoFit cover = VideoFit(
    sizeFactor: -0.5,
    aspectRatio: -1,
    alignment: Alignment.center,
  );

  static const VideoFit fitWidth = VideoFit(
    sizeFactor: -1.5,
  );

  static const VideoFit fitHeight = VideoFit(
    sizeFactor: -2.5,
  );

  static const VideoFit ar4_3 = VideoFit(
    aspectRatio: 4.0 / 3.0,
  );

  static const VideoFit ar16_9 = VideoFit(
    aspectRatio: 16.0 / 9.0,
  );
}
