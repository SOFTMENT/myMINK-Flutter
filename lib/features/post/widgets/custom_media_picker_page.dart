import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

enum PickerMode { image, video }

class CustomMediaPickerResult {
  CustomMediaPickerResult({required this.assets, required this.cameraFiles});
  final List<AssetEntity> assets; // gallery selections
  final List<File> cameraFiles; // camera captures
}

class CustomMediaPickerPage extends StatefulWidget {
  const CustomMediaPickerPage({
    super.key,
    required this.mode,
    this.maxCount = 4,
    this.title,
  });

  final PickerMode mode;
  final int maxCount; // images: 4, video: 1
  final String? title;

  @override
  State<CustomMediaPickerPage> createState() => _CustomMediaPickerPageState();
}

class _CustomMediaPickerPageState extends State<CustomMediaPickerPage> {
  final _picker = ImagePicker();

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;

  final _assets = <AssetEntity>[];
  final _selected = <AssetEntity>{};
  final _cameraFiles = <File>[]; // shown in grid, count toward limit

  bool _loading = true;
  bool _hasMore = true;
  int _page = 0;

  bool get _isVideo => widget.mode == PickerMode.video;
  int get _max => _isVideo ? 1 : widget.maxCount;

  int get _pickedCount => _selected.length + _cameraFiles.length;
  int get _remainingSlots => _max - _pickedCount;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final type = _isVideo ? RequestType.video : RequestType.image;
    _albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
      filterOption: FilterOptionGroup(
        videoOption: const FilterOption(
          durationConstraint: DurationConstraint(max: Duration(minutes: 5)),
        ),
      ),
    );

    _currentAlbum = _albums.isNotEmpty ? _albums.first : null;
    await _loadMore(refresh: true);
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_currentAlbum == null) return;
    if (!refresh && !_hasMore) return;

    setState(() => _loading = true);
    if (refresh) {
      _page = 0;
      _assets.clear();
      _selected.clear();
      _hasMore = true;
    }

    final pageAssets =
        await _currentAlbum!.getAssetListPaged(page: _page, size: 80);
    _assets.addAll(pageAssets);
    _hasMore = pageAssets.length == 80;
    _page++;

    if (mounted) setState(() => _loading = false);
  }

  void _showLimitSnack() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You can select up to $_max items.')),
    );
  }

  Future<void> _onCamera() async {
    // Respect overall max before opening camera (images mode)
    if (!_isVideo && _remainingSlots <= 0) {
      _showLimitSnack();
      return;
    }

    XFile? x;
    if (_isVideo) {
      x = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } else {
      x = await _picker.pickImage(source: ImageSource.camera);
    }
    if (x == null) return;

    final f = File(x.path);

    // For video: return immediately (no confirm)
    if (_isVideo) {
      Navigator.pop(
        context,
        CustomMediaPickerResult(assets: const [], cameraFiles: [f]),
      );
      return;
    }

    // For images: add capture if we still have room
    if (_remainingSlots <= 0) {
      _showLimitSnack();
      return;
    }
    _cameraFiles.add(f);
    setState(() {}); // shows it in the grid with a checkmark
  }

  void _toggle(AssetEntity a) {
    if (_isVideo) {
      // Single-select; return immediately (no confirm)
      Navigator.pop(
        context,
        CustomMediaPickerResult(assets: [a], cameraFiles: const []),
      );
      return;
    }

    // Images mode:
    if (_selected.contains(a)) {
      _selected.remove(a);
    } else {
      if (_remainingSlots <= 0) {
        _showLimitSnack();
        return;
      }
      _selected.add(a);
    }
    setState(() {});
  }

  // Allow removing a captured camera image by tapping it
  void _toggleCameraFile(int index) {
    // Only in images mode. Remove on tap to free up a slot.
    if (_isVideo) return;
    if (index < 0 || index >= _cameraFiles.length) return;
    _cameraFiles.removeAt(index);
    setState(() {});
  }

  void _done() {
    Navigator.pop(
      context,
      CustomMediaPickerResult(
        assets: _selected.toList(),
        cameraFiles: _cameraFiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? (_isVideo ? 'Select Video' : 'Select Photos');
    final pickedCount = _pickedCount;

    // Grid layout:
    // [0] Camera tile
    // [1 .. cameraFilesLen] Captured camera thumbnails (Image.file)
    // [cameraFilesLen+1 .. ] Gallery assets (AssetEntityImageProvider)
    final cameraLen = _cameraFiles.length;
    final totalGridCount = 1 /*camera tile*/ + cameraLen + _assets.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          if (!_isVideo) // no confirm for video mode
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: pickedCount > 0 ? _done : null,
                style: TextButton.styleFrom(
                  backgroundColor: pickedCount > 0
                      ? AppColors.primaryRed
                      : const Color.fromARGB(255, 253, 128, 128),
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Confirm ($pickedCount/$_max)'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _loading && _assets.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.extentAfter < 800 && !_loading) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: totalGridCount,
                        itemBuilder: (_, i) {
                          // [0] camera tile
                          if (i == 0) {
                            return InkWell(
                              onTap: _onCamera,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                            );
                          }

                          // [1 .. cameraLen] captured camera thumbnails
                          if (i >= 1 && i <= cameraLen) {
                            final camIndex = i - 1;
                            final file = _cameraFiles[camIndex];
                            return GestureDetector(
                              onTap: () => _toggleCameraFile(camIndex),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(file, fit: BoxFit.cover),
                                  ),
                                  // Always marked as selected
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Remaining are gallery assets
                          final assetIndex = i - 1 - cameraLen; // shift
                          final a = _assets[assetIndex];
                          final selected = _selected.contains(a);

                          return GestureDetector(
                            onTap: () => _toggle(a),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image(
                                    image: AssetEntityImageProvider(
                                      a,
                                      isOriginal: false,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (a.type == AssetType.video)
                                  const Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: Icon(Icons.videocam,
                                        color: Colors.white),
                                  ),
                                if (selected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            // Removed the "X photo captured" footer — now shown inline in grid
          ],
        ),
      ),
    );
  }
}
