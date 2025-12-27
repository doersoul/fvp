import 'package:flutter/material.dart';
import 'package:fvp/src/player.dart';
import 'package:fvp/src/video/models/value_observer.dart';
import 'package:fvp/src/video/models/video_fit.dart';
import 'package:fvp/src/video/utils/orientation_utils.dart';
import 'package:fvp/src/video/views/video_view_inner.dart';

typedef VideoCoverBuilder = Widget Function(BuildContext context, VideoFit fit);

typedef VideoSkinBuilder = Widget Function(
  VideoViewState viewState,
  Size viewSize,
  Rect texturePosition,
);

class VideoView extends StatefulWidget {
  static const String fullScreenRoute = '__media_kit_video_full_screen__';

  final Player player;
  final double? width;
  final double? height;
  final Color color;
  final VideoFit fit;
  final bool showCoverFirst;
  final VoidCallback? onEnterFullScreen;
  final VoidCallback? onExitFullScreen;
  final WidgetBuilder? backgroundBuilder;
  final VideoCoverBuilder? coverBuilder;
  final VideoSkinBuilder? skinBuilder;

  const VideoView({
    super.key,
    required this.player,
    this.width,
    this.height,
    required this.color,
    required this.fit,
    this.showCoverFirst = true,
    this.onEnterFullScreen,
    this.onExitFullScreen,
    this.backgroundBuilder,
    this.coverBuilder,
    this.skinBuilder,
  });

  @override
  State<StatefulWidget> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
  final ValueObserver<bool> _observer = ValueObserver(true);

  bool fullScreen = false;

  bool _changed = false;

  @override
  void didUpdateWidget(VideoView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.player != oldWidget.player) {
      _observer.value = true;
    }
  }

  @override
  void dispose() {
    _observer.dispose();

    super.dispose();
  }

  Future<void> enterFullScreen() async {
    if (fullScreen) {
      return;
    }

    fullScreen = true;

    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final Future<Null> exitFuture = navigator.push(
      PageRouteBuilder<Null>(
        settings: const RouteSettings(name: VideoView.fullScreenRoute),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: VideoViewInner(
              state: this,
              fit: VideoFit.contain,
              color: Colors.black,
              observer: _observer,
            ),
          );
        },
      ),
    );

    // will lead to rebuild
    if (widget.onEnterFullScreen != null) {
      widget.onEnterFullScreen!.call();
    } else {
      OrientationUtils.hideSystemBar();
    }

    final Size? videoSize = widget.player.textureSize.value;
    final double videoWidth = videoSize?.width ?? -1;
    final double videoHeight = videoSize?.height ?? -1;
    final Orientation orientation = MediaQuery.of(context).orientation;

    // will lead to rebuild
    if (videoWidth >= videoHeight) {
      if (orientation == Orientation.portrait) {
        OrientationUtils.setOrientationLandscape();

        _changed = true;
      }
    } else {
      if (orientation == Orientation.landscape) {
        OrientationUtils.setOrientationPortrait();

        _changed = true;
      }
    }

    await exitFuture;

    fullScreen = false;

    if (_changed) {
      if (videoWidth >= videoHeight) {
        OrientationUtils.setOrientationPortrait();
      } else {
        OrientationUtils.setOrientationLandscape();
      }
    }

    // will lead to rebuild
    if (widget.onExitFullScreen != null) {
      widget.onExitFullScreen!.call();
    } else {
      OrientationUtils.showSystemBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox.shrink();

    if (!fullScreen) {
      child = VideoViewInner(
        state: this,
        fit: widget.fit,
        color: widget.color,
      );
    }

    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}
