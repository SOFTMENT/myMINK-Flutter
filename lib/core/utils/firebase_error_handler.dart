class FirebaseErrorHandler {
  static String getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please check and try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use. Please use a different email.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-email':
        return 'The email address is not valid. Please check and try again.';
      default:
        return 'An unknown error occurred. Please try again later.';
    }
  }
}
