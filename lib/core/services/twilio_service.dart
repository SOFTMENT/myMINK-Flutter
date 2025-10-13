import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mymink/core/constants/api_constants.dart';

class TwilioService {
  static String _twilioUrl =
      'https://verify.twilio.com/v2/Services/${ApiConstants.TWILIO_VERIFY_SERVICE_SID}/Verifications';
  static final String accountSid = ApiConstants.TWILIO_ACCOUNT_SID;
  static final String authToken = ApiConstants.TWILIO_AUTH_TOKEN; // plain text
  static final String basicAuth =
      "Basic ${base64Encode(utf8.encode("$accountSid:$authToken"))}";

  static String _twilioVerificationCheckUrl =
      'https://verify.twilio.com/v2/Services/${ApiConstants.TWILIO_VERIFY_SERVICE_SID}/VerificationCheck';

  /// Verifies the Twilio code for the given phone number
  static Future<String?> verifyTwilioCode(
      String phoneNumber, String code) async {
    try {
      final encodedPhoneNumber = Uri.encodeComponent(phoneNumber);
      final parameters = "To=$encodedPhoneNumber&Code=$code";

      final response = await http.post(
        Uri.parse(_twilioVerificationCheckUrl),
        headers: {
          HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
          HttpHeaders.authorizationHeader: basicAuth,
        },
        body: parameters,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'approved') {
          return null; // Verification successful
        } else {
          return "Verification code is invalid or expired. Please resend a new code and try again.";
        }
      } else {
        return "Failed to verify code. Status code: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  /// Sends a Twilio verification code to the given phone number
  static Future<String?> sendTwilioVerification(String phoneNumber) async {
    try {
      final encodedPhoneNumber = Uri.encodeComponent(phoneNumber);
      final parameters = "To=$encodedPhoneNumber&Channel=sms";

      final response = await http.post(
        Uri.parse(_twilioUrl),
        headers: {
          HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
          HttpHeaders.authorizationHeader: basicAuth,
        },
        body: parameters,
      );

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'pending') {
          return null; // Success
        } else {
          return "Mobile number is incorrect";
        }
      } else {
        return "Failed to send verification. Status code: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
