import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../services/media.dart';

/// Shows a post's photo or video, or a coloured cover when it has none.
class PostMedia extends StatelessWidget {
  final FarmPost post;
  final double aspectRatio;
  final bool interactive;
  const PostMedia({
    super.key,
    required this.post,
    this.aspectRatio = 4 / 3,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final path = post.mediaPath;
    final missing = path == null || !mediaExists(path);
    Widget child;
    if (post.mediaType == MediaType.none || missing) {
      child = CategoryCover(
        category: categoryOf(post.category),
        missing: post.mediaType != MediaType.none,
      );
    } else if (post.mediaType == MediaType.image) {
      child = GestureDetector(
        onTap: interactive
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FullScreenMedia(post: post)),
              )
            : null,
        child: Hero(tag: 'media-${post.id}', child: _image(path)),
      );
    } else {
      child = InlineVideo(path: path, post: post, interactive: interactive);
    }
    return AspectRatio(aspectRatio: aspectRatio, child: child);
  }
}

Widget _image(String path, {BoxFit fit = BoxFit.cover}) => kIsWeb
    ? Image.network(path, fit: fit, width: double.infinity)
    : Image.file(File(path), fit: fit, width: double.infinity);

VideoPlayerController _controllerFor(String path) => kIsWeb
    ? VideoPlayerController.networkUrl(Uri.parse(path))
    : VideoPlayerController.file(File(path));

class CategoryCover extends StatelessWidget {
  final PostCategory category;
  final bool missing;
  const CategoryCover({
    super.key,
    required this.category,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(category.color);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.35)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Text(
              category.emoji,
              style: TextStyle(
                fontSize: 150,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Center(
            child: Text(category.emoji, style: const TextStyle(fontSize: 56)),
          ),
          if (missing)
            const Positioned(
              left: 12,
              bottom: 10,
              child: Text(
                'Media not on this device',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

/// Plays in place; shows the first frame with a play button until tapped.
class InlineVideo extends StatefulWidget {
  final String path;
  final FarmPost post;
  final bool interactive;
  const InlineVideo({
    super.key,
    required this.path,
    required this.post,
    this.interactive = true,
  });

  @override
  State<InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<InlineVideo> {
  late final VideoPlayerController _c = _controllerFor(widget.path);
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c
        .initialize()
        .then((_) {
          if (!mounted) return;
          _c.setLooping(true);
          setState(() => _ready = true);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
    _c.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return CategoryCover(
        category: categoryOf(widget.post.category),
        missing: true,
      );
    }
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _c.value.size.width,
                height: _c.value.size.height,
                child: VideoPlayer(_c),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_ready)
            GestureDetector(
              onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _c.value.isPlaying ? 0 : 1,
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _ready
                        ? _fmt(_c.value.duration - _c.value.position)
                        : 'Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_ready && widget.interactive)
            Positioned(
              right: 6,
              bottom: 6,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                color: Colors.white,
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  _c.pause();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenMedia(post: widget.post),
                    ),
                  );
                },
              ),
            ),
          if (_ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

class FullScreenMedia extends StatefulWidget {
  final FarmPost post;
  const FullScreenMedia({super.key, required this.post});

  @override
  State<FullScreenMedia> createState() => _FullScreenMediaState();
}

class _FullScreenMediaState extends State<FullScreenMedia> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == MediaType.video &&
        widget.post.mediaPath != null) {
      _c = _controllerFor(widget.post.mediaPath!)
        ..initialize().then((_) {
          if (!mounted) return;
          _c!
            ..setLooping(true)
            ..play();
          setState(() {});
        })
        ..addListener(() {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final c = _c;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          p.title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: p.mediaType == MediaType.image
                  ? InteractiveViewer(
                      child: Hero(
                        tag: 'media-${p.id}',
                        child: _image(p.mediaPath!, fit: BoxFit.contain),
                      ),
                    )
                  : c == null || !c.value.isInitialized
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),
            ),
          ),
          if (c != null && c.value.isInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _fmt(c.value.position),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          if (p.note.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  p.note,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
