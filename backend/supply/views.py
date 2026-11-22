from django.db import transaction
from django.http import HttpResponse
from django.utils.dateparse import parse_date
from openpyxl import Workbook
from openpyxl.styles import Font
from django.db.models import F, Sum
from rest_framework import mixins, viewsets
from rest_framework.decorators import action, api_view
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.response import Response

from .models import Department, Notification, Order, Product, StockMovement, Supplier, User
from .permissions import RoleWrite
from .serializers import (DepartmentSerializer, MeSerializer, MovementSerializer, NotificationSerializer,
                          OrderSerializer, ProductSerializer, SupplierSerializer)

R = User.Role


@api_view(["GET"])
def me(request):
    return Response(MeSerializer(request.user).data)


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    permission_classes = [RoleWrite]
    write_roles = (R.ADMIN,)
    search_fields = ["name"]


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [RoleWrite]
    write_roles = (R.ADMIN, R.SUPPLY, R.WAREHOUSE)
    search_fields = ["name", "kind", "barcode"]
    ordering_fields = ["name", "stock", "price"]

    @action(detail=False)
    def low_stock(self, request):
        qs = self.get_queryset().filter(stock__lte=F("min_stock") + F("reserved"))
        return Response(ProductSerializer(qs, many=True).data)

    @action(detail=False)
    def by_barcode(self, request):
        """QR-skaner: kod bo‘yicha aniq mahsulotni topadi."""
        code = request.query_params.get("code", "").strip()
        p = self.get_queryset().filter(barcode=code).first() if code else None
        if not p:
            raise NotFound("Bu kod bilan mahsulot topilmadi.")
        return Response(ProductSerializer(p).data)


class SupplierViewSet(viewsets.ModelViewSet):
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer
    permission_classes = [RoleWrite]
    write_roles = (R.ADMIN, R.SUPPLY)
    search_fields = ["name"]


class MovementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = StockMovement.objects.select_related("product")
    serializer_class = MovementSerializer
    filterset_fields = ["product"]

    def get_queryset(self):
        if self.request.user.role == R.FACULTY:
            raise PermissionDenied("Ombor harakati sizga ochiq emas.")
        return super().get_queryset()


class OrderViewSet(mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    serializer_class = OrderSerializer
    search_fields = ["reason", "product__name", "department__name"]
    ordering_fields = ["created_at", "status"]

    def get_queryset(self):
        qs = Order.objects.select_related("department", "product")
        u = self.request.user
        if u.role == R.FACULTY:
            qs = qs.filter(department=u.department)
        status = self.request.query_params.get("status")
        return qs.filter(status=status) if status else qs

    def perform_create(self, serializer):
        u = self.request.user
        if u.role not in (R.FACULTY, R.ADMIN):
            raise PermissionDenied("Buyurtmani fakultet mas’uli yoki administrator yuboradi.")
        dept = u.department if u.role == R.FACULTY else serializer.validated_data.get("department")
        if not dept:
            raise ValidationError({"department": "Bo‘limni ko‘rsating."})
        order = serializer.save(created_by=u, department=dept)
        for s in User.objects.filter(role=R.SUPPLY):
            Notification.objects.create(user=s, text=f"Yangi buyurtma {order.number}")

    # ---- Ish jarayoni (workflow) ----
    def _step(self, request, roles, from_status):
        if request.user.role not in roles:
            raise PermissionDenied("Bu amal sizning rolingiz uchun emas.")
        order = Order.objects.select_for_update().get(pk=self.kwargs["pk"])
        if order.status != from_status:
            raise ValidationError(f"Buyurtma holati '{order.get_status_display()}'. Bu amalni bajarib bo‘lmaydi.")
        order.handled_by = request.user
        return order

    def _done(self, order, text):
        order.save()
        Notification.objects.create(user=order.created_by, text=f"{order.number}: {text}")
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def review(self, request, pk=None):
        """Ta’minot xodimi: ombor qoldig‘ini tekshiradi — yetarli bo‘lsa tayyor, yo‘q bo‘lsa xarid."""
        order = self._step(request, (R.SUPPLY,), Order.Status.NEW)
        p = Product.objects.select_for_update().get(pk=order.product_id)
        take = min(p.available, order.quantity)  # boshqa buyurtmalar band qilganini hisobga oladi
        p.reserved += take
        p.save(update_fields=["reserved"])
        order.reserved_qty = take
        if take == order.quantity:
            order.status, order.note = Order.Status.READY, "Omborda mavjud, band qilindi"
        else:
            order.status, order.purchase_qty = Order.Status.PURCHASING, order.quantity - take
            order.note = f"Omborda {take} band qilindi, xarid: {order.purchase_qty}"
        return self._done(order, order.get_status_display())

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def reject(self, request, pk=None):
        order = self._step(request, (R.SUPPLY, R.LEADER), Order.Status.NEW)
        note = request.data.get("note", "").strip()
        if not note:
            raise ValidationError({"note": "Rad etish sababini yozing."})
        order.status, order.note = Order.Status.REJECTED, note
        return self._done(order, f"rad etildi — {note}")

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def cancel(self, request, pk=None):
        """Ta’minot/admin: xarid yoki tayyor buyurtmani bekor qiladi, band qilingan zaxira bo‘shatiladi."""
        if request.user.role not in (R.SUPPLY, R.ADMIN):
            raise PermissionDenied("Bu amal sizning rolingiz uchun emas.")
        order = Order.objects.select_for_update().get(pk=pk)
        if order.status not in (Order.Status.PURCHASING, Order.Status.READY):
            raise ValidationError("Faqat xarid jarayonidagi yoki tayyor buyurtmani bekor qilish mumkin.")
        note = request.data.get("note", "").strip()
        if not note:
            raise ValidationError({"note": "Bekor qilish sababini yozing."})
        Product.objects.filter(pk=order.product_id).update(reserved=F("reserved") - order.reserved_qty)
        order.status, order.note = Order.Status.REJECTED, f"Bekor qilindi: {note}"
        order.reserved_qty = order.purchase_qty = 0
        order.handled_by = request.user
        return self._done(order, f"bekor qilindi — {note}")

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def receive(self, request, pk=None):
        """Ombor mudiri: xarid qilingan mahsulotni qabul qiladi (kirim)."""
        order = self._step(request, (R.WAREHOUSE,), Order.Status.PURCHASING)
        p = Product.objects.select_for_update().get(pk=order.product_id)
        p.stock += order.purchase_qty
        p.reserved += order.purchase_qty  # kelgan mahsulot shu buyurtma uchun band
        p.save(update_fields=["stock", "reserved"])
        StockMovement.objects.create(product=p, kind=StockMovement.IN, quantity=order.purchase_qty,
                                     order=order, by=request.user,
                                     supplier_id=request.data.get("supplier") or None)
        order.reserved_qty = order.quantity
        order.status, order.purchase_qty, order.note = Order.Status.READY, 0, "Xarid qabul qilindi"
        return self._done(order, "mahsulot qabul qilindi")

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def deliver(self, request, pk=None):
        """Ombor mudiri: mahsulotni bo‘limga topshiradi (chiqim)."""
        order = self._step(request, (R.WAREHOUSE,), Order.Status.READY)
        p = Product.objects.select_for_update().get(pk=order.product_id)
        if p.stock < order.quantity:
            raise ValidationError("Omborda yetarli mahsulot yo‘q.")
        p.stock -= order.quantity
        p.reserved -= order.reserved_qty
        p.save(update_fields=["stock", "reserved"])
        StockMovement.objects.create(product=p, kind=StockMovement.OUT, quantity=order.quantity,
                                     order=order, by=request.user)
        order.status, order.note = Order.Status.DELIVERED, f"Topshirdi: {request.user.get_full_name() or request.user.username}"
        return self._done(order, "bo‘limga topshirildi")


class NotificationViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    @action(detail=False, methods=["post"])
    def read_all(self, request):
        self.get_queryset().update(is_read=True)
        return Response({"ok": True})


@api_view(["GET"])
def summary(request):
    """Rahbariyat uchun umumiy ko‘rsatkichlar va bo‘limlar kesimida xarajat."""
    if request.user.role not in (R.ADMIN, R.LEADER, R.SUPPLY):
        raise PermissionDenied("Hisobotlar sizga ochiq emas.")
    spend = (Order.objects.filter(status__in=["purchasing", "ready", "delivered"])
             .values("department__name").annotate(total=Sum(F("quantity") * F("product__price"))))
    by_status = Order.objects.values("status").annotate(n=Sum(1))
    return Response({
        "products": Product.objects.count(),
        "low_stock": Product.objects.filter(stock__lte=F("min_stock") + F("reserved")).count(),
        "orders_by_status": {r["status"]: r["n"] for r in by_status},
        "spend_by_department": [{"department": r["department__name"], "total": r["total"]} for r in spend],
    })


@api_view(["GET"])
def export_xlsx(request):
    """Excel eksport: ?kind=orders (from/to sanalar bilan) yoki ?kind=stock."""
    kind = request.query_params.get("kind", "orders")
    allowed = (R.ADMIN, R.LEADER, R.SUPPLY) + ((R.WAREHOUSE,) if kind == "stock" else ())
    if request.user.role not in allowed:
        raise PermissionDenied("Hisobotlar sizga ochiq emas.")
    wb = Workbook()
    ws = wb.active
    if kind == "stock":
        ws.title = "Ombor"
        ws.append(["Mahsulot", "Turi", "Birlik", "Narxi", "Qoldiq", "Band", "Mavjud", "Minimum"])
        for p in Product.objects.all():
            ws.append([p.name, p.kind, p.unit, float(p.price), p.stock, p.reserved, p.available, p.min_stock])
    else:
        ws.title = "Buyurtmalar"
        ws.append(["№", "Bo‘lim", "Mahsulot", "Miqdor", "Summa", "Holat", "Sana", "Izoh"])
        qs = Order.objects.select_related("department", "product")
        d1, d2 = parse_date(request.query_params.get("from", "")), parse_date(request.query_params.get("to", ""))
        if d1:
            qs = qs.filter(created_at__date__gte=d1)
        if d2:
            qs = qs.filter(created_at__date__lte=d2)
        for o in qs:
            ws.append([o.number, o.department.name, o.product.name, o.quantity, float(o.quantity * o.product.price),
                       o.get_status_display(), o.created_at.strftime("%Y-%m-%d"), o.note])
    for c in ws[1]:
        c.font = Font(bold=True)
    for col in ws.columns:
        ws.column_dimensions[col[0].column_letter].width = min(40, max(len(str(c.value or "")) for c in col) + 3)
    ws.freeze_panes = "A2"
    resp = HttpResponse(content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    resp["Content-Disposition"] = f'attachment; filename="unisupply_{kind}.xlsx"'
    wb.save(resp)
    return resp
