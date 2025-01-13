import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TwilioService {
  static const String _twilioUrl =
      "https://verify.twilio.com/v2/Services/VAcb99097ca8dabc2d7a3c421c51d8c221/Verifications";
  static const String _authToken =
      "Basic QUMxOWJiNTc5NWQ5OGYzNTZhMzI5Y2M0ZGYzYmEzNTcyNjoxMDRlZmI3YzAyOTg0ZmNiNzZjNzNkNDE2M2M3YTcyNg==";

  static const String _twilioVerificationCheckUrl =
      "https://verify.twilio.com/v2/Services/VAcb99097ca8dabc2d7a3c421c51d8c221/VerificationCheck";

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
          HttpHeaders.authorizationHeader: _authToken,
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
          HttpHeaders.authorizationHeader: _authToken,
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
