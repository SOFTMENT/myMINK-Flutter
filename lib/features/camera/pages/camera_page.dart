import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/navigation/main_tabbar.dart';
import 'package:mymink/features/post/widgets/create_post_sheet_content.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);
  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  // Permission tri-state: null = unknown (don’t show denied UI yet)
  PermissionStatus? _camStatus;

  bool _isSettingUp = false;
  int _session = 0; // invalidates in-flight async work

  bool get _isInitialized => _controller?.value.isInitialized == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Resolve permission & start session only if on this tab
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshPermission();
      final main = context.findAncestorStateOfType<MainTabBarState>();
      if (main == null || main.selectedIndex == 3) {
        _startCameraSession();
      }
    });
  }

  // ---- Permission helpers ---------------------------------------------------

  Future<void> _refreshPermission() async {
    _camStatus = await Permission.camera.status;
    if (mounted) setState(() {});
  }

  Future<bool> _ensurePermission() async {
    // Refresh current status first
    await _refreshPermission();
    if (!mounted) return false;

    if (_camStatus!.isGranted) return true;

    if (_camStatus!.isDenied ||
        _camStatus!.isLimited ||
        _camStatus!.isRestricted) {
      // Ask once (iOS will pause app while sheet is up)
      _camStatus = await Permission.camera.request();
      if (mounted) setState(() {});
    }

    return _camStatus!.isGranted;
  }

  // ---- Camera session control ----------------------------------------------

  Future<void> _startCameraSession() async {
    if (_isSettingUp || !mounted) return;
    _isSettingUp = true;
    final mySession = ++_session;

    try {
      // IMPORTANT: permission BEFORE touching CameraController
      final granted = await _ensurePermission();
      if (!mounted || mySession != _session) return;
      if (!granted) {
        // Not granted: do not create controller; UI will show hint
        setState(() {});
        return;
      }

      _cameras = await availableCameras();
      if (!mounted || mySession != _session) return;
      if (_cameras.isEmpty) {
        throw StateError('No cameras available');
      }

      final temp = CameraController(
        _cameras.first, // back camera
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await temp.initialize();
      if (!mounted || mySession != _session) {
        await temp.dispose();
        return;
      }

      // Swap in the ready controller
      final old = _controller;
      _controller = temp;
      setState(() {});
      await old?.dispose();
    } catch (e) {
      if (mounted && mySession == _session) {
        // Keep controller null so UI shows Retry
        await _controller?.dispose();
        _controller = null;
        setState(() {});
      }
    } finally {
      _isSettingUp = false;
    }
  }

  Future<void> _stopCameraSession() async {
    _session++; // invalidate any in-flight init
    final c = _controller;
    _controller = null;

    if (c != null) {
      try {
        await c.dispose();
      } catch (_) {}
    }
  }

  // ---- Lifecycle / tab hooks -----------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await _stopCameraSession();
    } else if (state == AppLifecycleState.resumed) {
      // Small debounce avoids transient false negatives on iOS resume
      await Future.delayed(const Duration(milliseconds: 150));
      await _refreshPermission();
      final main = context.findAncestorStateOfType<MainTabBarState>();
      if (main == null || main.selectedIndex == 3) {
        _startCameraSession();
      }
    }
  }

  /// Called by MainTabBar when switching *away* from this tab.
  void pauseCamera() => _stopCameraSession();

  /// Called by MainTabBar when switching *into* this tab.
  void resumeCamera() {
    if (!_isInitialized && !_isSettingUp) {
      _startCameraSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCameraSession();
    super.dispose();
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // While permission is unknown or we’re in setup, show a neutral loader.
    if (_camStatus == null || _isSettingUp) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isGranted = _camStatus!.isGranted;
    final isPermanentlyDenied = _camStatus!.isPermanentlyDenied;

    // Only show the permission UI when we KNOW it’s denied and no controller
    if (!isGranted && _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: Colors.white70, size: 28),
                const SizedBox(height: 12),
                const Text(
                  'Allow camera to take photos and videos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isPermanentlyDenied
                      ? openAppSettings
                      : _startCameraSession, // re-requests if not permanent
                  child: Text(isPermanentlyDenied
                      ? 'Enable in Settings'
                      : 'Allow Camera'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _startCameraSession,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If permission granted but controller not ready yet → loader
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previewSize = _controller!.value.previewSize;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (previewSize != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                // Swap width/height because camera reports landscape sizes
                child: SizedBox(
                  width: previewSize.height,
                  height: previewSize.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const SizedBox.expand(),

          // Bottom sheet content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: CreatePostSheetContent(
                  outerContext: context,
                  showCloseButton: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
