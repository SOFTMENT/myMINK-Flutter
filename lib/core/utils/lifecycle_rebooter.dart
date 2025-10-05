// lib/core/utils/lifecycle_rebooter.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

class LifecycleRebooter extends StatefulWidget {
  const LifecycleRebooter({
    super.key,
    required this.child,
    required this.routerNavKey,
    this.threshold = const Duration(minutes: 20),
  });

  final Widget child;
  final GlobalKey<NavigatorState> routerNavKey;
  final Duration threshold;

  @override
  State<LifecycleRebooter> createState() => _LifecycleRebooterState();
}

class _LifecycleRebooterState extends State<LifecycleRebooter>
    with WidgetsBindingObserver {
  DateTime? _backgroundAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundAt != null) {
      final away = DateTime.now().difference(_backgroundAt!);
      if (away >= widget.threshold) {
        // Workaround for go_router + Phoenix:
        // 1) navigate to a safe root, 2) then rebirth.
        widget.routerNavKey.currentContext?.go(AppRoutes.welcome);
        Future.microtask(() => Phoenix.rebirth(context));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
