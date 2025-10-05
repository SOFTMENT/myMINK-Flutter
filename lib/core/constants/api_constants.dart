class ApiConstants {
  static const String awsVideoBaseURL =
      'https://res.cloudinary.com/dyzki97p7/video/upload/w_540/q_auto:eco/v1758904461';
  static const String awsImageBaseURL = 'https://d34hi5x7melm0j.cloudfront.net';
  static const String weatherBaseUrl = 'ss';

  static String getFullVideoURL(String key) {
    return '${awsVideoBaseURL}/${key}';
  }
}
