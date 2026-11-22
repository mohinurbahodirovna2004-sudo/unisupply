from rest_framework.test import APITestCase
from .models import Department, Product, User


class WorkflowTest(APITestCase):
    def setUp(self):
        d = Department.objects.create(name="AT")
        self.fac = User.objects.create_user("f", password="x", role="faculty", department=d)
        self.sup = User.objects.create_user("s", password="x", role="supply")
        self.wh = User.objects.create_user("w", password="x", role="warehouse")
        self.p = Product.objects.create(name="Klaviatura", price=100, stock=4, min_stock=1)

    def test_full_flow(self):
        self.client.force_authenticate(self.fac)
        r = self.client.post("/api/orders/", {"product": self.p.id, "quantity": 10, "reason": "xona"})
        self.assertEqual(r.status_code, 201)
        oid = r.data["id"]
        self.assertEqual(self.client.post(f"/api/orders/{oid}/review/").status_code, 403)  # rol tekshiruvi
        self.client.force_authenticate(self.sup)
        r = self.client.post(f"/api/orders/{oid}/review/")
        self.assertEqual((r.data["status"], r.data["purchase_qty"]), ("purchasing", 6))
        self.client.force_authenticate(self.wh)
        self.assertEqual(self.client.post(f"/api/orders/{oid}/receive/").data["status"], "ready")
        self.assertEqual(self.client.post(f"/api/orders/{oid}/deliver/").data["status"], "delivered")
        self.p.refresh_from_db()
        self.assertEqual(self.p.stock, 0)
        self.assertEqual(self.client.post(f"/api/orders/{oid}/deliver/").status_code, 400)  # qayta topshirib bo‘lmaydi

    def _order(self, q):
        self.client.force_authenticate(self.fac)
        return self.client.post("/api/orders/", {"product": self.p.id, "quantity": q, "reason": "x"}).data["id"]

    def test_reservation_and_cancel(self):
        a, b = self._order(3), self._order(3)
        self.client.force_authenticate(self.sup)
        self.assertEqual(self.client.post(f"/api/orders/{a}/review/").data["reserved_qty"], 3)
        r = self.client.post(f"/api/orders/{b}/review/")
        self.assertEqual((r.data["reserved_qty"], r.data["purchase_qty"]), (1, 2))  # 4 ta zaxira ikki marta sotilmaydi
        self.p.refresh_from_db()
        self.assertEqual(self.p.available, 0)
        self.assertEqual(self.client.post(f"/api/orders/{a}/cancel/", {"note": "kerak emas"}).data["status"], "rejected")
        self.p.refresh_from_db()
        self.assertEqual(self.p.available, 3)

    def test_export(self):
        self.client.force_authenticate(self.sup)
        r = self.client.get("/api/reports/export/?kind=orders")
        self.assertEqual(r.status_code, 200)
        self.assertIn("spreadsheetml", r["Content-Type"])
        self.client.force_authenticate(self.fac)
        self.assertEqual(self.client.get("/api/reports/export/").status_code, 403)

    def test_barcode_lookup(self):
        self.client.force_authenticate(self.fac)
        r = self.client.get(f"/api/products/by_barcode/?code={self.p.barcode}")
        self.assertEqual((r.status_code, r.data["id"]), (200, self.p.id))
        self.assertEqual(self.client.get("/api/products/by_barcode/?code=yo-q").status_code, 404)
        self.client.force_authenticate(self.wh)
        self.assertEqual(self.client.patch(f"/api/products/{self.p.id}/", {"barcode": "4780001234567"}).status_code, 200)
        self.assertEqual(self.client.get("/api/products/by_barcode/?code=4780001234567").status_code, 200)

    def test_admin_qr(self):
        from django.contrib import admin as dj
        from .admin import ProductAdmin
        self.assertIn("data:image/svg+xml", ProductAdmin(Product, dj.site).qr(self.p))
