from django.core.management.base import BaseCommand
from supply.models import Product


class Command(BaseCommand):
    help = "Kodi yo‘q mahsulotlarga UNI-xxxxxx kodini beradi (eski ma’lumotlar uchun)"

    def handle(self, *a, **kw):
        n = 0
        for p in Product.objects.filter(barcode__isnull=True):
            p.save()
            n += 1
        self.stdout.write(self.style.SUCCESS(f"{n} ta mahsulotga kod berildi"))
