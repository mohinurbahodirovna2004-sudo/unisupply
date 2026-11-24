import os

from django.core.management.base import BaseCommand
from supply.models import User


class Command(BaseCommand):
    help = "ADMIN_USERNAME va ADMIN_PASSWORD berilsa, administrator yaratadi (mavjud bo‘lsa parolga tegmaydi)"

    def handle(self, *a, **kw):
        u, pw = os.getenv("ADMIN_USERNAME"), os.getenv("ADMIN_PASSWORD")
        if not (u and pw):
            return self.stdout.write("ADMIN_USERNAME/ADMIN_PASSWORD berilmagan — o‘tkazib yuborildi")
        obj, new = User.objects.get_or_create(username=u, defaults=dict(role="admin", is_staff=True, is_superuser=True))
        if new:
            obj.set_password(pw)
            obj.save()
        self.stdout.write(self.style.SUCCESS(f"Administrator {'yaratildi' if new else 'mavjud'}: {u}"))
