import 'package:http/http.dart' as http;
import 'package:mymink/core/constants/email_verification_type.dart';

class EmailService {
  static Future<String?> sendVerificationEmail(
      String email, int randomNumber, VerificationType type) async {
    return sendMail(
      toName: 'my MINK',
      toEmail: email,
      subject: type == VerificationType.EMAIL_VERIFICATION
          ? 'Email Verification'
          : 'Retrieve Password',
      body: type == VerificationType.EMAIL_VERIFICATION
          ? getEmailVerificationTemplate(
              randomNumber.toString(),
            )
          : getPasswordResetTemplate(
              randomNumber.toString(),
            ),
    );
  }

  static String getPasswordResetTemplate(String randomNumber) {
    return """
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify your login</title>
    <!--[if mso]><style type="text/css">body, table, td, a { font-family: Arial, Helvetica, sans-serif !important; }</style><![endif]-->
  </head>
  <body style="font-family: Helvetica, Arial, sans-serif; margin: 0px; padding: 0px; background-color: #ffffff;">
    <table role="presentation"
      style="width: 100%; border-collapse: collapse; border: 0px; border-spacing: 0px; font-family: Arial, Helvetica, sans-serif; background-color: rgb(255, 255, 255);">
      <tbody>
        <tr>
          <td align="center" style="padding: 1rem 2rem; vertical-align: top; width: 100%;">
            <table role="presentation" style="max-width: 600px; border-collapse: collapse; border: 0px; border-spacing: 0px; text-align: left;">
              <tbody>
                <tr>
                  <td style="padding: 40px 0px 0px;">
                    <div style="text-align: left;">
                      <div style="padding-bottom: 20px;">
                        <img src="http://mymink.com.au/logo.png" alt="Logo" style="width: 88px;">
                      </div>
                    </div>
                    <div style="background-color: rgb(255, 255, 255);">
                      <div style="color: rgb(0, 0, 0); text-align: left;">
                        <h2 style="margin: 1rem 0">Password Reset</h2>
                        <p style="padding-bottom: 16px">Please use the below code for verification</p>
                        <p style="padding-bottom: 16px">
                          <strong style="font-size: 130%;">$randomNumber</strong>
                        </p>
                        <p style="padding-bottom: 16px">If you did not request this, you can ignore this email.</p>
                        <p style="padding-bottom: 16px">Thanks,<br>my MINK Team</p>
                      </div>
                    </div>
                    <div style="padding-top: 20px; color: rgb(153, 153, 153); text-align: center;">
                      <p style="padding-bottom: 16px">©2023 My Mink Pty Ltd</p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  </body>
  </html>
  """;
  }

  static String getEmailVerificationTemplate(String randomNumber) {
    return """
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">

    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Verify your login</title>
      <!--[if mso]><style type="text/css">body, table, td, a { font-family: Arial, Helvetica, sans-serif !important; }</style><![endif]-->
    </head>

    <body style="font-family: Helvetica, Arial, sans-serif; margin: 0px; padding: 0px; background-color: #ffffff;">
      <table role="presentation"
        style="width: 100%; border-collapse: collapse; border: 0px; border-spacing: 0px; font-family: Arial, Helvetica, sans-serif; background-color: rgb(255, 255, 255);">
        <tbody>
          <tr>
            <td align="center" style="padding: 1rem 2rem; vertical-align: top; width: 100%;">
              <table role="presentation" style="max-width: 600px; border-collapse: collapse; border: 0px; border-spacing: 0px; text-align: left;">
                <tbody>
                  <tr>
                    <td style="padding: 40px 0px 0px;">
                      <div style="text-align: left;">
                        <div style="padding-bottom: 20px;">
                          <img src="http://mymink.com.au/logo.png" alt="Logo" style="width: 88px;">
                        </div>
                      </div>
                      <div style="background-color: rgb(255, 255, 255);">
                        <div style="color: rgb(0, 0, 0); text-align: left;">
                          <h2 style="margin: 1rem 0">Verification code</h2>
                          <p style="padding-bottom: 16px">Please use the below code for email verification:</p>
                          <p style="padding-bottom: 16px"><strong style="font-size: 130%;">$randomNumber</strong></p>
                          <p style="padding-bottom: 16px">If you did not request this, you can ignore this email.</p>
                          <p style="padding-bottom: 16px">Thanks,<br>my MINK Team</p>
                        </div>
                      </div>
                      <div style="padding-top: 20px; color: rgb(153, 153, 153); text-align: center;">
                        <p style="padding-bottom: 16px">©2023 My MINK Pty Ltd</p>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </td>
          </tr>
        </tbody>
      </table>
    </body>

    </html>
    """;
  }

  static Future<String?> sendMail({
    required String toName,
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    try {
      var response = await http.post(
        Uri.parse('https://mymink.com.au/mail/sendmail.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': toName,
          'email': toEmail,
          'subject': subject,
          'body': body,
        },
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return 'Failed to send email';
      }
    } catch (e) {
      return 'Error sending email: ${e.toString()}';
    }
  }
}
