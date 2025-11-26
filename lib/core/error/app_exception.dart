class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException([this.message = 'Something went wrong', this.prefix]);

  @override
  String toString() {
    return '${prefix ?? "Error"}: $message';
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
      : super(message ?? 'Error During Communication', 'Error');
}

class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message ?? 'Invalid Request', 'Bad Request');
}

class UnauthorisedException extends AppException {
  UnauthorisedException([String? message]) : super(message ?? 'Unauthorised', 'Unauthorised');
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message ?? 'Invalid Input', 'Invalid Input');
}
