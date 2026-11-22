from rest_framework.permissions import SAFE_METHODS, BasePermission


class RoleWrite(BasePermission):
    """O‘qish — hamma autentifikatsiyadan o‘tganlarga; yozish — view.write_roles dagilarga."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.method in SAFE_METHODS or request.user.role in getattr(view, "write_roles", ())
