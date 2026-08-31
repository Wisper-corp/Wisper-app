import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

/// A video shown the way a feed shows one: its own first frame, with a play
/// button over it.
///
/// The frame comes from video_player, which is already a dependency — the
/// controller is initialised and never played, so what is on screen is a real
/// frame of the video rather than a stand-in. Before it loads, and if it never
/// does, a dark poster with the same play button stands in its place, so the
/// tile never changes shape.
class VideoPoster extends StatefulWidget {
  const VideoPoster({
    super.key,
    required this.url,
    required this.onTap,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 12,
    this.maxHeight,
  });

  final String url;
  final VoidCallback onTap;

  /// Used until the video reports its own, so the tile does not jump.
  final double aspectRatio;
  final double borderRadius;

  /// Stops a portrait clip running the height of the screen. The poster keeps
  /// its proportions and narrows instead, which is what a tall video looks
  /// like in any messaging app.
  final double? maxHeight;

  @override
  State<VideoPoster> createState() => _VideoPosterState();
}

class _VideoPosterState extends State<VideoPoster> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadFirstFrame();
  }

  Future<void> _loadFirstFrame() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;

    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      // Never played: initialising is enough to have a frame to show.
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      // A frame that will not load is not worth failing the post over.
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ready && _controller!.value.aspectRatio > 0
        ? _controller!.value.aspectRatio
        : widget.aspectRatio;

    final poster = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius.r),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                const ColoredBox(color: Color(0xff17191C)),
              Center(
                child: Container(
                  width: 54.r,
                  height: 54.r,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32.sp,
                    semanticLabel: 'Play video',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.maxHeight == null) return poster;
    // The factors are the point: an Align without them fills the width it is
    // offered, which left a chat bubble stretched to full width with the
    // narrowed clip in a field of bubble colour. With them it takes the size
    // of what it holds, so the bubble follows the clip in. The Align still
    // earns its place by passing loose constraints down -- under a tight
    // parent the height cap would otherwise have nothing to bite on.
    // Anything wanting the poster centred in a wider space says so itself.
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: poster,
      ),
    );
  }
}
