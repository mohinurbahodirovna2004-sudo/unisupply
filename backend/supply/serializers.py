from rest_framework import serializers
from .models import Department, Notification, Order, Product, StockMovement, Supplier, User


class MeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "role", "department"]


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = "__all__"


class ProductSerializer(serializers.ModelSerializer):
    is_low = serializers.SerializerMethodField()
    available = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = "__all__"
        read_only_fields = ["stock", "reserved"]  # qoldiq faqat kirim/chiqim orqali o‘zgaradi

    def get_is_low(self, p):
        return p.available <= p.min_stock


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"


class OrderSerializer(serializers.ModelSerializer):
    number = serializers.ReadOnlyField()
    product_name = serializers.CharField(source="product.name", read_only=True)
    department_name = serializers.CharField(source="department.name", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = Order
        fields = ["id", "number", "department", "department_name", "product", "product_name", "quantity",
                  "reason", "needed_by", "status", "status_label", "purchase_qty", "reserved_qty", "note",
                  "created_by", "handled_by", "created_at", "updated_at"]
        read_only_fields = ["status", "purchase_qty", "reserved_qty", "note", "created_by", "handled_by"]
        extra_kwargs = {"department": {"required": False}, "quantity": {"min_value": 1}}


class MovementSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = StockMovement
        fields = "__all__"


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = "__all__"
