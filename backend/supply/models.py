from django.contrib.auth.models import AbstractUser
from django.db import models


class Department(models.Model):
    name = models.CharField(max_length=200, unique=True)

    def __str__(self):
        return self.name


class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = "admin", "Universitet administratori"
        LEADER = "leader", "Rektorat / rahbariyat"
        FACULTY = "faculty", "Fakultet yoki kafedra mas’uli"
        SUPPLY = "supply", "Ta’minot bo‘limi xodimi"
        WAREHOUSE = "warehouse", "Ombor mudiri"

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.FACULTY)
    department = models.ForeignKey(Department, null=True, blank=True, on_delete=models.SET_NULL, related_name="users")


class Product(models.Model):
    name = models.CharField(max_length=200)
    kind = models.CharField("turi", max_length=100, blank=True)
    unit = models.CharField(max_length=30, default="dona")
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    stock = models.PositiveIntegerField(default=0)
    reserved = models.PositiveIntegerField(default=0)  # tasdiqlangan buyurtmalar uchun band qilingan
    min_stock = models.PositiveIntegerField(default=0)
    barcode = models.CharField(max_length=64, unique=True, null=True, blank=True)  # QR-kod uchun

    def __str__(self):
        return self.name

    @property
    def available(self):
        return max(self.stock - self.reserved, 0)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if not self.barcode:  # har bir mahsulotga chop etish mumkin bo‘lgan QR kod
            self.barcode = f"UNI-{self.pk:06d}"
            super().save(update_fields=["barcode"])


class Supplier(models.Model):
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=40, blank=True)
    note = models.TextField(blank=True)

    def __str__(self):
        return self.name


class Order(models.Model):
    class Status(models.TextChoices):
        NEW = "new", "Yangi"
        PURCHASING = "purchasing", "Xarid jarayonida"
        READY = "ready", "Topshirishga tayyor"
        DELIVERED = "delivered", "Topshirildi"
        REJECTED = "rejected", "Rad etildi"

    department = models.ForeignKey(Department, on_delete=models.PROTECT, related_name="orders")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="orders")
    quantity = models.PositiveIntegerField()
    reason = models.CharField(max_length=300)
    needed_by = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.NEW)
    purchase_qty = models.PositiveIntegerField(default=0)
    reserved_qty = models.PositiveIntegerField(default=0)
    note = models.CharField(max_length=300, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="orders")
    handled_by = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL, related_name="handled_orders")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    @property
    def number(self):
        return f"UO-{self.pk:05d}"


class StockMovement(models.Model):
    IN, OUT = "in", "out"
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="movements")
    kind = models.CharField(max_length=3, choices=[(IN, "Kirim"), (OUT, "Chiqim")])
    quantity = models.PositiveIntegerField()
    order = models.ForeignKey(Order, null=True, blank=True, on_delete=models.SET_NULL, related_name="movements")
    supplier = models.ForeignKey(Supplier, null=True, blank=True, on_delete=models.SET_NULL)
    by = models.ForeignKey(User, on_delete=models.PROTECT)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    text = models.CharField(max_length=300)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
