// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/models/post_model.dart';

class MediaCarousel extends StatefulWidget {
  final List<MediaItem> media;
  final double? height;
  final double? borderRadius;
  final bool showIndicators;
  final bool autoPlay;

  const MediaCarousel({
    Key? key,
    required this.media,
    this.height,
    this.borderRadius,
    this.showIndicators = true,
    this.autoPlay = true,
  }) : super(key: key);

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  int _currentIndex = 0;
  final List<VideoPlayerController?> _videoControllers = [];
  final List<bool> _videoInitialized = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant MediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media != widget.media) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    _videoControllers.clear();
    _videoInitialized.clear();
    for (final m in widget.media) {
      if (m.type == 'video') {
        final controller = VideoPlayerController.network(m.url);
        _videoControllers.add(controller);
        _videoInitialized.add(false);
        controller.setLooping(true);
        controller.setVolume(0);
        controller.initialize().then((_) {
          if (widget.autoPlay) controller.play();
          setState(() {
            _videoInitialized[_videoControllers.indexOf(controller)] = true;
          });
        });
      } else {
        _videoControllers.add(null);
        _videoInitialized.add(false);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    super.dispose();
  }

  void _disposeControllers() {
    for (final c in _videoControllers) {
      c?.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? 8.0;
    final height = widget.height ?? 350;
    if (widget.media.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(child: Icon(Icons.image)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final m = widget.media[index];
              if (m.type == 'video') {
                final controller = _videoControllers[index];
                final isInitialized = _videoInitialized[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: isInitialized && controller != null
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio > 0
                                ? controller.value.aspectRatio
                                : 9 / 16,
                            child: VideoPlayer(controller),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surface,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                );
              } else {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: CachedNetworkImage(
                    imageUrl: m.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        if (widget.showIndicators && widget.media.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.media.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == i
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
