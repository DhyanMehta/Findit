import 'package:flutter/material.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const ErrorBoundary({super.key, required this.child, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static Widget wrapWithErrorHandling({
    required Widget child,
    String? errorMessage,
  }) {
    return ErrorBoundary(errorMessage: errorMessage, child: child);
  }
}

class AuthErrorHandler {
  static String getCleanErrorMessage(dynamic error) {
    String errorString = error.toString();

    // Handle common Firebase/Pigeon errors
    if (errorString.contains('PigeonUserDetails') ||
        errorString.contains('List<Object?>') ||
        errorString.contains('type cast')) {
      return 'Authentication service error. Please restart the app and try again.';
    }

    // Handle network errors
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Handle Firebase Auth specific errors
    if (errorString.contains('Exception:')) {
      return errorString.replaceAll('Exception:', '').trim();
    }

    // Return cleaned up error message
    return errorString;
  }

  static void showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(getCleanErrorMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getCleanErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
