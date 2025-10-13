import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/music/data/models/music_model.dart';

class MusicListView extends StatelessWidget {
  final List<Result> songs;
  final void Function(int) onPlay;
  const MusicListView({
    super.key,
    required this.songs,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      shrinkWrap: true,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final thumb = (song.image != null && song.image!.length > 2)
            ? song.image![2].link
            : null;

        return GestureDetector(
          onTap: () {
            onPlay(index);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumb != null
                      ? SizedBox(
                          height: 60,
                          width: 60,
                          child: CustomImage(
                              imageKey: null,
                              imageFullUrl: thumb,
                              width: 80,
                              height: 80),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.music_note, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name ?? 'Unknown Title',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if ((song.explicitContent ?? 0) == 1) ...[
                            const Icon(Icons.explicit,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              song.primaryArtists ?? 'Unknown Artist',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: const EdgeInsets.only(left: 10, right: 2),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
