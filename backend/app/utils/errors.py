class AppException(Exception):
    """Application-level error mapped to a consistent JSON error response."""

    def __init__(self, status_code: int, message: str, error_code: str = "ERROR"):
        self.status_code = status_code
        self.message = message
        self.error_code = error_code
        super().__init__(message)


class NotFoundException(AppException):
    def __init__(self, message: str, error_code: str = "NOT_FOUND"):
        super().__init__(404, message, error_code)


class BadRequestException(AppException):
    def __init__(self, message: str, error_code: str = "BAD_REQUEST"):
        super().__init__(400, message, error_code)


class ConflictException(AppException):
    def __init__(self, message: str, error_code: str = "CONFLICT"):
        super().__init__(409, message, error_code)


class UnauthorizedException(AppException):
    def __init__(self, message: str = "Authentication required", error_code: str = "UNAUTHORIZED"):
        super().__init__(401, message, error_code)


class ForbiddenException(AppException):
    def __init__(self, message: str = "You do not have permission", error_code: str = "FORBIDDEN"):
        super().__init__(403, message, error_code)


class ValidationException(AppException):
    def __init__(self, message: str, error_code: str = "VALIDATION_ERROR"):
        super().__init__(422, message, error_code)