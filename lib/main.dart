import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:mymink/amplifyconfiguration.dart';

import 'package:mymink/firebase_options.dart';
import 'package:mymink/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  await configureAmplify();
  await FlutterBranchSdk.init();
  runApp(App());
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

  final theme = ThemeData.light().copyWith(
    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'TimesNewRoman',
        ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
    scaffoldBackgroundColor: Colors.white,
  );

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
