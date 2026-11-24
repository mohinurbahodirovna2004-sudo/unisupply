from django.urls import include, path
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register("departments", views.DepartmentViewSet)
router.register("products", views.ProductViewSet)
router.register("suppliers", views.SupplierViewSet)
router.register("orders", views.OrderViewSet, basename="order")
router.register("movements", views.MovementViewSet)
router.register("notifications", views.NotificationViewSet, basename="notification")

urlpatterns = [
    path("me/", views.me),
    path("auth/change_password/", views.change_password),
    path("reports/summary/", views.summary),
    path("reports/export/", views.export_xlsx),
    path("", include(router.urls)),
]
