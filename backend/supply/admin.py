import base64

import qrcode
import qrcode.image.svg
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html

from . import models as m

admin.site.register(m.User, UserAdmin)
for model in (m.Department, m.Supplier, m.Order, m.StockMovement, m.Notification):
    admin.site.register(model)


@admin.register(m.Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "kind", "stock", "reserved", "barcode", "qr")
    readonly_fields = ("qr",)
    search_fields = ("name", "barcode")

    @admin.display(description="QR-kod (chop etib yopishtiring)")
    def qr(self, p):
        if not p.barcode:
            return "—"
        svg = qrcode.make(p.barcode, image_factory=qrcode.image.svg.SvgPathImage, box_size=10).to_string()
        b64 = base64.b64encode(svg).decode()
        return format_html('<img src="data:image/svg+xml;base64,{}" width="110" height="110" alt="{}">', b64, p.barcode)
