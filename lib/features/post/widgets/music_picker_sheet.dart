// lib/features/post/widgets/music_picker_sheet.dart

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mymink/features/post/data/models/jamendo_response.dart';

class MusicPickerSheet extends StatefulWidget {
  final void Function(Track) onTrackSelected;
  const MusicPickerSheet({Key? key, required this.onTrackSelected})
      : super(key: key);

  @override
  _MusicPickerSheetState createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  String? _playingTrackId;
  String? _loadingTrackId;

  bool _loading = true;
  List<Track> _tracks = [];

  Timer? _debounce;
  static const _clientId = '54492a60';

  @override
  void initState() {
    super.initState();
    _fetchTracks('nature');
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchTracks([String? name]) async {
    setState(() => _loading = true);

    final uri = Uri.https(
      'api.jamendo.com',
      '/v3.0/tracks/',
      {
        'client_id': _clientId,
        'format': 'jsonpretty',
        'limit': '20',
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final jamendo = JamendoResponse.parse(resp.body);
      setState(() {
        _tracks = jamendo.results;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive == true) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final term = _searchCtrl.text.trim();
      _fetchTracks(term.isEmpty ? null : term);
    });
  }

  Future<void> _handlePlayPause(Track track) async {
    if (_playingTrackId == track.id) {
      await _player.pause();
      setState(() {
        _playingTrackId = null;
        _loadingTrackId = null;
      });
      return;
    }

    setState(() => _loadingTrackId = track.id);
    await _player.stop();
    await _player.play(UrlSource(track.audioUrl));
    setState(() {
      _playingTrackId = track.id;
      _loadingTrackId = null;
    });
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;
    return Container(
      height: sheetHeight,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // draggable handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search audio',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // track list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.only(left: 10),
                    itemCount: _tracks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (_, i) {
                      final t = _tracks[i];
                      final isPlaying = t.id == _playingTrackId;
                      final isBuffering = t.id == _loadingTrackId;

                      return ListTile(
                        onTap: () => widget.onTrackSelected(t),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            t.albumImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(t.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${t.artistName} • ${_formatDuration(t.duration)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        trailing: isBuffering
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () => _handlePlayPause(t),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
