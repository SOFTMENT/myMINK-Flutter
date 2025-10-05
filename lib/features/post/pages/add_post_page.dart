import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/navigation/main_tabbar.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/services/translation_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/post/data/models/jamendo_response.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/features/post/widgets/music_picker_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class AddPostPage extends ConsumerStatefulWidget {
  AddPostPage(
      {super.key,
      required this.files,
      required this.postType,
      this.businessId = null});

  final List<File> files;
  final PostType postType;
  final String? businessId;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends ConsumerState<AddPostPage> {
  var _isLoading = false;
  String? _isLoadingLbl;
  final _captionController = TextEditingController();
  late PageController _pageController;
  int _currentPage = 0;
  late VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  double postVideoRatio = 1;
  File? thumbnailFile;
  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.9);

    // Add listener to detect page changes
    _pageController.addListener(() {
      int nextPage =
          _pageController.page!.round(); // Get the current page index
      if (nextPage != _currentPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });

    if (widget.postType == PostType.video) {
      _initializeVideoPlayer();

      ImageService.generateThumbnail(widget.files.first.path).then((thumbnail) {
        if (thumbnail != null) {
          ImageService.convertUint8ListToFile(thumbnail).then((onValue) {
            thumbnailFile = onValue;
          });
        }
      });
    } else {
      _videoPlayerController = null;
    }
  }

  Future<void> _showMusicSheet() async {
    _videoPlayerController?.setVolume(0); // Mute current video

    final selectedTrack = await showModalBottomSheet<Track>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(241, 0, 0, 0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MusicPickerSheet(
        onTrackSelected: (Track track) {
          Navigator.pop(context, track); // return selected track
        },
      ),
    );

    if (selectedTrack != null) {
      setState(() {
        _isLoading = true;
        _isLoadingLbl = "Merging music...";
      });

      try {
        final audioFile = await _downloadAudioToFile(selectedTrack.audioUrl);
        final merged =
            await _mergeVideoWithAudio(widget.files.first, audioFile);

        setState(() {
          widget.files[0] = merged;
        });

        await _initializeVideoPlayer(); // Re-init
        _videoPlayerController?.seekTo(Duration.zero); // Restart video
        _videoPlayerController?.play();
      } catch (e) {
        print("Merge failed: $e");
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingLbl = null;
        });
      }
    }

    _videoPlayerController?.setVolume(1.0); // Restore volume
  }

  Future<void> _initializeVideoPlayer() async {
    postVideoRatio = await getVideoAspectRatio(widget.files.first);
    _videoPlayerController = VideoPlayerController.file(widget.files.first)
      ..setLooping(true)
      ..setVolume(1.0)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoPlayerController!.play(); // Autoplay the video
        });
      });
  }

  /// Downloads an MP3 from [url] into a temporary file.
  Future<File> _downloadAudioToFile(String url) async {
    final resp = await http.get(Uri.parse(url));
    final tmp = await getTemporaryDirectory();
    final out = File('${tmp.path}/selected_audio.mp3');
    await out.writeAsBytes(resp.bodyBytes);
    return out;
  }

  /// Uses ffmpeg to remux your original [video] with the new [audio].
  /// Assumes both streams are already compatible (same length not required).
  Future<File> _mergeVideoWithAudio(File video, File audio) async {
    final tmp = await getTemporaryDirectory();
    final output =
        File('${tmp.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final cmd = [
      '-i',
      video.path,
      '-i',
      audio.path,
      '-c:v',
      'copy',
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-shortest',
      output.path,
    ].join(' ');
    await FFmpegKit.execute(cmd);
    return output;
  }

  Future<double> getVideoAspectRatio(File videoFile) async {
    try {
      final videoPlayerController = VideoPlayerController.file(videoFile);
      await videoPlayerController.initialize();
      final videoWidth = videoPlayerController.value.size.width;
      final videoHeight = videoPlayerController.value.size.height;
      videoPlayerController.dispose();

      return videoWidth / videoHeight;
    } catch (e) {
      print("Error calculating video aspect ratio: $e");
      return 0.0; // Default aspect ratio in case of error
    }
  }

  void _sharePostPressed() async {
    if (_isLoading) return; // Prevent double tap while uploading

    // setState(() {
    //   _isLoading = true;
    //   _isLoadingLbl = "Uploading...";
    // });

    final container = ProviderScope.containerOf(context);

    final postId = FirebaseService().db.collection(Collections.posts).doc().id;
    final caption = _captionController.text.trim();
    String? enCaption;
    if (caption.isNotEmpty) {
      enCaption = await TranslationService.shared.translateText(text: caption);
    }
    PostModel postModel = PostModel(
        postID: postId,
        isPromoted: widget.businessId == null ? true : false,
        postCreateDate: DateTime.now(),
        postType: widget.postType.name,
        uid: FirebaseService().auth.currentUser!.uid,
        caption: caption,
        enCaption: enCaption,
        isActive: true,
        bid: widget.businessId);

    Future<void> uploadFuture = PostService.startUploadAndPushPost(
      context: mainTabKey.currentState!.getContext(),
      container: container,
      postModel: postModel,
      files: widget.files,
      postType: widget.postType,
      thumbnailFile: thumbnailFile,
      postVideoRatio: postVideoRatio,
    );

    if (widget.businessId != null) {
      Navigator.popUntil(
        context,
        (route) => route.settings.name == AppRoutes.businessDetailsPage,
      );
    } else {
      mainTabKey.currentState?.jumpToTab(0);
      Navigator.popUntil(
        context,
        (route) => route.settings.name == AppRoutes.tabbar,
      );
    }

    await uploadFuture;

    // if (mounted) {
    //   setState(() {
    //     _isLoading = false;
    //     _isLoadingLbl = null;
    //   });
    // }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 16), // Add padding to the entire body
          child: DismissKeyboardOnTap(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  widget.postType == PostType.video
                      ? _isVideoInitialized
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: postVideoRatio,
                                  child: VideoPlayer(_videoPlayerController!),
                                ),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            )
                      : SizedBox(
                          height: 400,
                          child: PageView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: _pageController,
                            itemCount: widget.files.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    right: index == widget.files.length - 1
                                        ? 0
                                        : 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    widget.files[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        autocorrect: false,
                        maxLines: 8,
                        controller: _captionController,
                        minLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        textAlignVertical: TextAlignVertical
                            .top, // Add this line to align the text at the top
                        decoration: buildInputDecoration(
                            alignLabelWithHint: true,
                            labelText: "Write a caption here",
                            prefixIcon: null),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 32),
                    child: Row(
                      children: [
                        if (widget.postType == PostType.image)
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            iconSize: 44,
                            onPressed: () async {
                              try {
                                Uint8List imageBytes = await widget
                                    .files[_currentPage]
                                    .readAsBytes();

                                Uint8List? editedImage = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageEditor(
                                      image:
                                          imageBytes, // <-- Uint8List of image
                                    ),
                                  ),
                                );

                                if (editedImage != null) {
                                  // Convert Uint8List to File
                                  File editedFile =
                                      await ImageService.convertUint8ListToFile(
                                          editedImage);

                                  // Use the in-memory File as needed
                                  setState(() {
                                    widget.files[_currentPage] = editedFile;
                                  });

                                  print(
                                      'Temporary file created: ${editedFile.path}');
                                }
                              } catch (e) {}
                            },
                            icon: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    12), // Apply the circular border radius
                                child: Stack(
                                  fit: StackFit.loose,
                                  children: [
                                    // The image
                                    Image.file(
                                      widget.files[_currentPage],
                                      fit: BoxFit.cover,
                                      width: 44,
                                      height: 44,
                                    ),
                                    // Semi-transparent black overlay
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(56, 0, 0, 0)
                                            .withValues(
                                                alpha:
                                                    0.28), // Black with 50% opacity
                                        borderRadius: BorderRadius.circular(
                                            12), // Apply same border radius
                                      ),
                                    ),
                                    // Centered Icon
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Icon(
                                          Icons.tune_outlined,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        if (widget.postType == PostType.video &&
                            widget.businessId == null)
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            iconSize: 44,
                            onPressed: () async {
                              _showMusicSheet();
                            },
                            icon: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    12), // Apply the circular border radius
                                child: Stack(
                                  fit: StackFit.loose,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .black, // Black with 50% opacity
                                        borderRadius: BorderRadius.circular(
                                            12), // Apply same border radius
                                      ),
                                    ),
                                    // Centered Icon
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Icon(
                                          Icons.music_note_outlined,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: 100,
                          height: 44,
                          child: CustomButton(
                              text: _isLoading ? 'Uploading...' : 'Share Post',
                              onPressed: _isLoading ? () {} : _sharePostPressed,
                              backgroundColor: AppColors.textBlack),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Center(
            child: ProgressHud(
              message: _isLoadingLbl,
            ),
          ),
      ]),
    );
  }
}
