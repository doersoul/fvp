import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:fvp/src/global.dart';
import 'package:fvp/src/player.dart';
import 'package:fvp/src/video/models/value_observer.dart';
import 'package:fvp/src/video/models/video_fit.dart';
import 'package:fvp/src/video/views/video_view.dart';

class VideoViewInner extends StatefulWidget {
  final VideoViewState state;
  final VideoFit fit;
  final Color color;
  final ValueObserver<bool>? observer;

  const VideoViewInner({
    super.key,
    required this.state,
    required this.fit,
    required this.color,
    this.observer,
  });

  @override
  State<StatefulWidget> createState() => _VideoViewInnerState();

  bool get showCoverFirst => state.widget.showCoverFirst;

  Player get player => state.widget.player;

  WidgetBuilder? get backgroundBuilder => state.widget.backgroundBuilder;

  VideoCoverBuilder? get coverBuilder => state.widget.coverBuilder;

  VideoSkinBuilder? get skinBuilder => state.widget.skinBuilder;
}

class _VideoViewInnerState extends State<VideoViewInner> {
  late List<StreamSubscription> _subscriptions;

  late bool _playable;
  late int _textureId;
  late double _videoWidth;
  late double _videoHeight;
  late bool _ready;

  @override
  void initState() {
    super.initState();

    _initPlayerListener();
    _initObserverListener();
  }

  @override
  void didUpdateWidget(VideoViewInner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.player != oldWidget.player) {
      _disposePlayerListener(oldWidget);
      _initPlayerListener();
    }

    if (widget.observer != oldWidget.observer) {
      _disposeObserverListener(oldWidget);
      _initObserverListener();
    }
  }

  @override
  void dispose() {
    _disposePlayerListener(widget);
    _disposeObserverListener(widget);

    super.dispose();
  }

  void _initPlayerListener() {
    _playable = false;
    _textureId = -1;
    _videoWidth = -1;
    _videoHeight = -1;
    _ready = false;

    widget.player.textureId.addListener(_playerListener);
    widget.player.textureSize.addListener(_playerListener);

    _subscriptions = [
      widget.player.stateStream.listen(_playerListener),
    ];

    _playerListener();
  }

  void _disposePlayerListener(VideoViewInner inner) {
    inner.player.textureId.removeListener(_playerListener);
    inner.player.textureSize.removeListener(_playerListener);

    for (final subscription in _subscriptions) {
      subscription.cancel().ignore();
    }
  }

  Future<void> _playerListener([dynamic _]) async {
    _playable = _playable ||
        PlaybackState.playing == widget.player.state ||
        widget.player.position > 0;

    final int textureId = widget.player.textureId.value ?? -1;
    final Size? size = widget.player.textureSize.value;
    final double videoWidth = size?.width ?? -1;
    final double videoHeight = size?.height ?? -1;

    bool ready = textureId > -1 && videoWidth > 0 && videoHeight > 0;
    if (widget.showCoverFirst) {
      ready = ready && _playable;
    }

    if (_textureId != textureId ||
        _videoWidth != videoWidth ||
        _videoHeight != videoHeight ||
        _ready != ready) {
      _textureId = textureId;
      _videoWidth = videoWidth;
      _videoHeight = videoHeight;
      _ready = ready;

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _initObserverListener() {
    widget.observer?.addListener(_observerListener);
  }

  void _disposeObserverListener(VideoViewInner inner) {
    inner.observer?.removeListener(_observerListener);
  }

  void _observerListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposePlayerListener(widget);
      _initPlayerListener();

      if (mounted) {
        setState(() {});
      }
    });
  }

  Size _applyAspectRatio(BoxConstraints constraints, double aspectRatio) {
    assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);

    constraints = constraints.loosen();

    double width = constraints.maxWidth;
    double height = width;

    if (width.isFinite) {
      height = width / aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }

  double _getAspectRatio(BoxConstraints constraints, double aspectRatio) {
    if (aspectRatio < 0) {
      aspectRatio = _videoWidth / _videoHeight;
    } else if (aspectRatio.isInfinite) {
      aspectRatio = constraints.maxWidth / constraints.maxHeight;
    }

    return aspectRatio;
  }

  Size _getTextureSize(BoxConstraints constraints, VideoFit fit) {
    Size childSize = _applyAspectRatio(
      constraints,
      _getAspectRatio(constraints, -1),
    );

    double sizeFactor = fit.sizeFactor;
    if (-1.0 < sizeFactor && sizeFactor < -0.0) {
      sizeFactor = max(
        constraints.maxWidth / childSize.width,
        constraints.maxHeight / childSize.height,
      );
    } else if (-2.0 < sizeFactor && sizeFactor < -1.0) {
      sizeFactor = constraints.maxWidth / childSize.width;
    } else if (-3.0 < sizeFactor && sizeFactor < -2.0) {
      sizeFactor = constraints.maxHeight / childSize.height;
    } else if (sizeFactor < 0) {
      sizeFactor = 1.0;
    }

    childSize = childSize * sizeFactor;

    return childSize;
  }

  Offset _getTextureOffset(
    BoxConstraints constraints,
    Size size,
    VideoFit fit,
  ) {
    final Alignment resolvedAlignment = fit.alignment;
    final Offset diff = (constraints.biggest - size) as Offset;

    return resolvedAlignment.alongOffset(diff);
  }

  Widget _buildTexture() {
    Widget texture = const SizedBox.shrink();
    if (_textureId > -1) {
      texture = RepaintBoundary(
        child: Texture(
          textureId: _textureId,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    // if (_rotate != 0 && _textureId > 0) {
    //   texture = RotatedBox(quarterTurns: _rotate ~/ 90, child: texture);
    // }

    return texture;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final List<Widget> stack = [
          Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: widget.color,
          )
        ];

        final Widget? background = widget.backgroundBuilder?.call(ctx);
        if (background != null) {
          stack.add(background);
        }

        if (!_ready) {
          final Widget? cover = widget.coverBuilder?.call(ctx, widget.fit);
          if (cover != null) {
            stack.add(
              Positioned.fromRect(
                rect: Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
                child: cover,
              ),
            );
          }
        } else {
          final Size size = _getTextureSize(constraints, widget.fit);

          final Offset offset = _getTextureOffset(
            constraints,
            size,
            widget.fit,
          );

          final Rect position = Rect.fromLTWH(
            offset.dx,
            offset.dy,
            size.width,
            size.height,
          );

          stack.add(Positioned.fromRect(
            rect: position,
            child: _buildTexture(),
          ));

          final Widget? skin = widget.skinBuilder?.call(
            widget.state,
            constraints.biggest,
            position,
          );
          if (skin != null) {
            stack.add(skin);
          }
        }

        return Stack(fit: StackFit.expand, children: stack);
      },
    );
  }
}
