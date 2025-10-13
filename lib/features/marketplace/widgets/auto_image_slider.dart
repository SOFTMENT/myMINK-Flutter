import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';

/// 9:6 auto image slider with 3s resume delay after user interaction
class AutoImageSlider extends StatefulWidget {
  final List<String> imageUrls;

  /// 9:6 by default (1.5)
  final double aspectRatio;

  /// Interval between automatic slides
  final Duration autoPlayInterval;

  /// Extra delay before autoplay resumes after user interaction
  final Duration resumeDelay;

  /// Slide animation duration
  final Duration slideDuration;

  /// Curve for page animation
  final Curve slideCurve;

  /// Show dot indicators
  final bool showIndicators;

  /// Tap callback for an image (index of tapped image)
  final ValueChanged<int>? onTap;

  /// Border radius for the slider
  final BorderRadiusGeometry borderRadius;

  /// Active/inactive dot colors & size
  final Color indicatorActiveColor;
  final Color indicatorColor;
  final double indicatorSize;
  final double indicatorSpacing;

  const AutoImageSlider({
    super.key,
    required this.imageUrls,
    this.aspectRatio = 9 / 6,
    this.autoPlayInterval = const Duration(seconds: 9),
    this.resumeDelay = const Duration(seconds: 9), // ← added
    this.slideDuration = const Duration(milliseconds: 450),
    this.slideCurve = Curves.easeOut,
    this.showIndicators = true,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.indicatorActiveColor = const Color(0xFFFFFFFF),
    this.indicatorColor = const Color(0x88FFFFFF),
    this.indicatorSize = 7,
    this.indicatorSpacing = 6,
  });

  @override
  State<AutoImageSlider> createState() => _AutoImageSliderState();
}

class _AutoImageSliderState extends State<AutoImageSlider> {
  late final PageController _controller;
  Timer? _timer;
  int _current = 0;
  bool _userIsInteracting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.imageUrls.length > 1) {
      _scheduleNext(widget.autoPlayInterval);
    }
  }

  @override
  void didUpdateWidget(covariant AutoImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _cancelTimer();
      if (widget.imageUrls.length > 1) {
        _scheduleNext(widget.autoPlayInterval);
      }
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext(Duration delay) {
    _cancelTimer();
    _timer = Timer(delay, () {
      if (!mounted || widget.imageUrls.length <= 1) return;

      if (_userIsInteracting) {
        // If still interacting, check again after a bit.
        _scheduleNext(widget.resumeDelay);
        return;
      }

      final next = (_current + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: widget.slideDuration,
        curve: widget.slideCurve,
      );

      // Schedule the following slide at the regular interval.
      _scheduleNext(widget.autoPlayInterval);
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: _buildPlaceholder(),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Slider
            Listener(
              onPointerDown: (_) {
                _userIsInteracting = true;
                _cancelTimer(); // stop timer while interacting
              },
              onPointerUp: (_) {
                _userIsInteracting = false;
                // ← wait 3s before resuming autoplay
                _scheduleNext(widget.resumeDelay);
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) {
                  setState(() => _current = i);
                  // If the page change was user-driven, we already
                  // scheduled on pointer up. For safety, ensure a resume.
                  if (!_userIsInteracting) {
                    // When autoplay changed the page, keep normal cadence.
                    _scheduleNext(widget.autoPlayInterval);
                  }
                },
                itemBuilder: (context, index) {
                  final url = widget.imageUrls[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTap?.call(index),
                    child: CustomImage(imageKey: url, width: 900, height: 600),
                  );
                },
              ),
            ),

            // Bottom gradient (optional)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0, -0.3),
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
              ),
            ),

            // Dots
            if (widget.showIndicators && widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.imageUrls.length, (i) {
                    final bool active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: widget.indicatorSpacing / 2,
                      ),
                      width: widget.indicatorSize * (active ? 1.4 : 1.0),
                      height: widget.indicatorSize,
                      decoration: BoxDecoration(
                        color: active
                            ? widget.indicatorActiveColor
                            : widget.indicatorColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE6E8EB),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 36, color: Colors.black38),
      ),
    );
  }
}
