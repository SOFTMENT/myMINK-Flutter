import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class MyVideoCacheManager extends CacheManager {
  static const key = 'myVideoCache';
  static MyVideoCacheManager? _instance;

  factory MyVideoCacheManager() {
    _instance ??= MyVideoCacheManager._();
    return _instance!;
  }

  MyVideoCacheManager._()
      : super(
          Config(key,
              stalePeriod: const Duration(days: 7), maxNrOfCacheObjects: 200),
        );

  // Define your custom getFilePath if needed without the override annotation.
  Future<String> getFilePath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$key';
  }
}
