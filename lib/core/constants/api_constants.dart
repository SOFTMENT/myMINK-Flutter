class ApiConstants {
  static const String awsVideoBaseURL =
      'https://mymink-storagea113e-dev.s3.ap-southeast-2.amazonaws.com';
  static const String awsImageBaseURL = 'https://d34hi5x7melm0j.cloudfront.net';
  static const String weatherBaseUrl = 'ss';

  static String getFullVideoURL(String key) {
    return '${awsVideoBaseURL}/${key}';
  }
}
