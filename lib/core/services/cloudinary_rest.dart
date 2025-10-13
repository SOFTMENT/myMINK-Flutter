import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

typedef UploadProgress = void Function(double fraction);

class CloudinaryVideoUploadResult {
  final String publicId;
  final String originalUrl;

  CloudinaryVideoUploadResult({
    required this.publicId,
    required this.originalUrl,
  });
}

class CloudinaryRest {
  static final Dio _dio = Dio();

  /// SHA-1 signature of alphabetically sorted params + api_secret
  /// Only include params you actually send (exclude file, api_key, signature).
  static String _sign(Map<String, String> params, String apiSecret) {
    final keys = params.keys.toList()..sort();
    final toSign = keys.map((k) => '$k=${params[k]}').join('&');
    return sha1.convert(utf8.encode('$toSign$apiSecret')).toString();
  }

  /// Build a compressed MP4 delivery URL.
  /// - keepAspect=false → force 9:16 (w×h) with smart crop
  /// - keepAspect=true  → scale by height only (keeps original AR)
  /// - Set [bitrate] to '' to remove the cap and let q_auto decide.
  /// - Set [fps] (e.g., 24) to downcap framerate.

  /// Signed upload (NO SDK). WARNING: keeping apiSecret in the app is insecure.
  static Future<CloudinaryVideoUploadResult> uploadVideoSigned({
    required File file,
    required String cloudName,
    required String apiKey,
    required String apiSecret,
    String folder = 'reels',
    String? publicId, // without extension
    UploadProgress? onProgress,

    // default delivery profile
  }) async {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Sign ONLY the params you’ll send (exclude file/api_key/signature)
    final paramsToSign = <String, String>{
      'folder': folder,
      'timestamp': timestamp,
      if (publicId != null) 'public_id': publicId,
    };
    final signature = _sign(paramsToSign, apiSecret);

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.uri.pathSegments.last),
      'api_key': apiKey,
      'timestamp': timestamp,
      'folder': folder,
      if (publicId != null) 'public_id': publicId,
      'signature': signature,
    });

    final endpoint = 'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

    try {
      final resp = await _dio.post(
        endpoint,
        data: form,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );

      final data = Map<String, dynamic>.from(resp.data as Map);
      final returnedPublicId = data['public_id'] as String;
      final originalUrl = (data['secure_url'] ?? data['url']) as String;

      return CloudinaryVideoUploadResult(
        publicId: returnedPublicId,
        originalUrl: originalUrl,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['error']?['message']?.toString() ?? e.message)
          : e.message;
      throw Exception('Cloudinary upload failed: $msg');
    }
  }

  /// Optional HEAD request to compare sizes quickly (Content-Length).
  static Future<int?> contentLength(String url) async {
    try {
      final res = await _dio.head(
        url,
        options: Options(followRedirects: true, validateStatus: (_) => true),
      );
      final cl = res.headers.value('content-length');
      return cl != null ? int.tryParse(cl) : null;
    } catch (_) {
      return null;
    }
  }
}
