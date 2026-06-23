class AppError(Exception):
    """Base for domain errors that routers translate into HTTP responses."""

    status_code = 400

    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class NotFoundError(AppError):
    status_code = 404


class ConflictError(AppError):
    status_code = 409


class ForbiddenError(AppError):
    status_code = 403


class UnauthorizedError(AppError):
    status_code = 401


class ValidationError(AppError):
    status_code = 422
