// ---------------------------------------------------------------------------
// GoalSight — Unified Error Model
// ---------------------------------------------------------------------------

sealed class AppError {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;

  static AppError from(Object error) {
    if (error is AppError) return error;
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('host')) {
      return NetworkError(
          message: 'Connection failed. Check your network.', cause: error);
    }
    if (msg.contains('permission denied') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('jwt')) {
      return PermissionError(
          message: "You don't have permission to access this.", cause: error);
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return NotFoundError(
          message: 'The requested item was not found.', cause: error);
    }
    if (msg.contains('storage') || msg.contains('bucket') || msg.contains('upload')) {
      return StorageError(
          message: 'Storage operation failed. Please try again.', cause: error);
    }
    return UnknownError(
        message: 'Something went wrong. Please try again.', cause: error);
  }
}

final class NetworkError extends AppError {
  const NetworkError({required super.message, super.cause});
}

final class DatabaseError extends AppError {
  const DatabaseError({required super.message, super.cause});
}

final class AuthError extends AppError {
  const AuthError({required super.message, super.cause});
}

final class PermissionError extends AppError {
  const PermissionError({required super.message, super.cause});
}

final class NotFoundError extends AppError {
  const NotFoundError({required super.message, super.cause});
}

final class StorageError extends AppError {
  const StorageError({required super.message, super.cause});
}

final class UnknownError extends AppError {
  const UnknownError({required super.message, super.cause});
}
