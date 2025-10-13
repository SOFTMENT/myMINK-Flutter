import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/amplifyconfiguration.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/services/notification_service.dart';
import 'package:mymink/core/utils/lifecycle_rebooter.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/features/post/data/services/post_service.dart';

import 'package:mymink/features/videocall/data/services/call_kit_initializer.dart';
import 'package:mymink/features/videocall/data/services/video_call_services.dart';

import 'package:mymink/firebase_options.dart';
import 'package:mymink/routes/app_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  VideoCallService.initAgoraToken();
  await NotificationService.init();
  await dotenv.load();
  await configureAmplify();
  await FlutterBranchSdk.init(
    enableLogging: true,
    branchAttributionLevel: BranchAttributionLevel.FULL,
  );

  //Agora
  CallkitInitializer.initialize(
      agoraAppId: ApiConstants.agoraAppId, navigatorKey: navigatorKey);

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://afb78f949e909e7f0ecb5041ca46986d@o4509213501489152.ingest.us.sentry.io/4509213502472192';
      // Adds request headers and IP for users,
      // visit: https://docs.sentry.io/platforms/dart/data-management/data-collected/ for more info
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: ProviderScope(
          child: LifecycleRebooter(
            child: App(),
            routerNavKey: navigatorKey,
            threshold: const Duration(minutes: 15),
          ),
        ),
      ),
    ),
  );
}

Future<void> configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ]);
    await Amplify.configure(amplifyconfig);
  } catch (e) {}
}

class App extends StatelessWidget {
  App({super.key});

  ThemeData get theme {
    // Create a base text theme with your desired font family.
    final baseTextTheme = ThemeData.light().textTheme.apply(
          fontFamily: 'TimesNewRoman',
        );
    // Override the subtitle1 style to have a fontSize of 14.
    return ThemeData.light().copyWith(
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 14.0),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14.0),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "my MINK",
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
