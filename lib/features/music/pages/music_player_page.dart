// pubspec.yaml dependencies (add these):
//   audioplayers: ^1.1.1
//   cached_network_image: ^3.2.3

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/features/music/data/models/music_model.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/gen/assets.gen.dart';

class MusicPlayerPage extends StatefulWidget {
  final List<Result> items;
  final int initialIndex;

  const MusicPlayerPage({
    Key? key,
    required this.items,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _player;
  late int _positionIndex;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  // Subscriptions so we can cancel on dispose
  late StreamSubscription<Duration> _durationSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<void> _completeSub;

  Result get _current => widget.items[_positionIndex];

  @override
  void initState() {
    super.initState();
    _positionIndex = widget.initialIndex;

    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    // Listen and update state
    _durationSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _onNext();
    });

    _playCurrent();
  }

  Future<void> _playCurrent() async {
    final url =
        (_current.downloadURL != null && _current.downloadURL!.length > 3)
            ? _current.downloadURL![3].link
            : null;
    if (url == null) return;

    await _player.stop();
    await _player.play(UrlSource(url));
    if (!mounted) return;
    setState(() => _isPlaying = true);
  }

  void _onPlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.resume();
    }
    if (!mounted) return;
    setState(() => _isPlaying = !_isPlaying);
  }

  void _onNext() {
    if (_positionIndex < widget.items.length - 1) {
      _positionIndex++;
      _resetAndPlay();
    }
  }

  void _onPrevious() {
    if (_positionIndex > 0) {
      _positionIndex--;
      _resetAndPlay();
    }
  }

  void _resetAndPlay() {
    _position = Duration.zero;
    _duration = Duration.zero;
    _playCurrent();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    // Stop playback and cancel all listeners
    _player.stop();
    _durationSub.cancel();
    _positionSub.cancel();
    _completeSub.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // thumbnail URL (iOS used index 2)
    final thumb = (_current.image != null && _current.image!.length > 2)
        ? _current.image![2].link!
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                if (thumb != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 48,
                    color: Colors.grey.shade200,
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 34),
                  child: CustomIconButton(
                    icon: Assets.images.em1688517695TrimmyBack.image(),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Song title & artist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _current.name ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _current.primaryArtists ?? 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Seek bar + times
            Column(
              children: [
                Slider(
                  min: 0.0,
                  max: _duration.inMilliseconds.toDouble(),
                  value: _position.inMilliseconds
                      .clamp(0, _duration.inMilliseconds)
                      .toDouble(),
                  onChanged: (double ms) {
                    final newPos = Duration(milliseconds: ms.round());
                    _player.seek(newPos);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(_position),
                          style: const TextStyle(fontSize: 12)),
                      Text(_format(_duration),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Controls: prev / play-pause / next
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                  onPressed: _onPrevious,
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  iconSize: 64,
                  color: AppColors.primaryRed,
                  onPressed: _onPlayPause,
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36,
                  onPressed: _onNext,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
