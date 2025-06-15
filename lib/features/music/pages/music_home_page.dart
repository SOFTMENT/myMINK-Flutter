import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/music/data/models/music_model.dart';
import 'package:mymink/features/music/data/services/music_service.dart';
import 'package:mymink/features/music/widgets/music_list.dart';

class MusicHomePage extends StatefulWidget {
  MusicHomePage({Key? key}) : super(key: key);

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  TextEditingController _searchController = TextEditingController();
  List<Result> _songs = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch('latest english');
  }

  Future<void> _fetch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await MusicService.searchSongs(query);
      setState(() {
        if (results.isEmpty) {
          _error = 'No music available';
        }

        _songs = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Called when the user taps search

  void _onSearch() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      // when user clears the field, show the initial 50 songs again
      _fetch('latest english');
    } else {
      final q = text.replaceAll(' ', '+');
      _fetch(q);
    }
  }

  void _onPlay(int index) {
    context.push(
      AppRoutes.musicPlayerPage,
      extra: {'items': _songs, 'index': index},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(title: 'Music'),
              const SizedBox(
                height: 20,
              ),
              SearchBarWithButton(
                  controller: _searchController,
                  onPressed: _onSearch,
                  hintText: 'Search'),
              const Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
                child: const Text(
                  'Top 50 - Global',
                  style: TextStyle(
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              Expanded(child: MusicListView(songs: _songs, onPlay: _onPlay)),
            ],
          ),
          if (_loading)
            Center(
              child: ProgressHud(),
            )
          else if (_error != null)
            Center(
              child: Text(_error!,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textGrey)),
            )
        ],
      ),
    );
  }
}
