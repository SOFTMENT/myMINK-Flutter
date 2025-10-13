import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String awsVideoBaseURL = dotenv.env["AWS_VIDEO_BASE_URL"] ?? "";
  static String awsImageBaseURL = dotenv.env["AWS_IMAGE_BASE_URL"] ?? "";
  static String googleAPIKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  static String agoraAppId = dotenv.env['AGORA_APP_ID'] ?? 'appid';
  static String cloudinaryName = dotenv.env["CLOUDINARY_CLOUD_NAME"] ?? "";
  static String cloudinaryApiKey = dotenv.env["CLOUD_API_KEY"] ?? "";
  static String cloudinaryApiSecret = dotenv.env["CLOUD_API_SECRET"] ?? "";
  static String openApiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
  static String googlePlacesApiKey =
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? 'YOUR_GOOGLE_PLACES_API_KEY';
  static String getFullVideoURL(String key) {
    print(awsVideoBaseURL);
    return '${awsVideoBaseURL}/${key}';
  }

  static String openWeatherApiKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';

  // If you use --dart-define or --dart-define-from-file
  static String TWILIO_ACCOUNT_SID = dotenv.env["TWILIO_ACCOUNT_SID"] ?? "";
  static String TWILIO_AUTH_TOKEN = dotenv.env["TWILIO_AUTH_TOKEN"] ?? "";
  static String TWILIO_VERIFY_SERVICE_SID =
      dotenv.env["TWILIO_VERIFY_SERVICE_SID"] ?? "";
}
