from django.core.management.base import BaseCommand
from supply.models import Department, Product, User


class Command(BaseCommand):
    help = "Demo ma’lumotlar: bo‘limlar, mahsulotlar va har bir rol uchun foydalanuvchi (parol: demo12345)"

    def handle(self, *a, **kw):
        depts = {n: Department.objects.get_or_create(name=n)[0] for n in
                 ["Rektorat", "Axborot texnologiyalari fakulteti", "Iqtisodiyot fakulteti", "Kutubxona", "Fizika laboratoriyasi"]}
        for n, k, u, pr, st, mn in [("Klaviatura", "Kompyuter jihozi", "dona", 120000, 4, 3),
                                    ("Sichqoncha", "Kompyuter jihozi", "dona", 80000, 12, 5),
                                    ("A4 qog‘oz", "Kanselyariya", "pachka", 55000, 40, 20),
                                    ("Printer kartridji", "Kanselyariya", "dona", 350000, 2, 4)]:
            Product.objects.get_or_create(name=n, defaults=dict(kind=k, unit=u, price=pr, stock=st, min_stock=mn))
        for username, role, dept in [("admin1", "admin", None), ("rektorat1", "leader", None),
                                     ("fakultet1", "faculty", "Axborot texnologiyalari fakulteti"),
                                     ("taminot1", "supply", None), ("ombor1", "warehouse", None)]:
            u, new = User.objects.get_or_create(username=username, defaults=dict(
                role=role, department=depts.get(dept), is_staff=role == "admin", is_superuser=role == "admin"))
            if new:
                u.set_password("demo12345"); u.save()
        self.stdout.write(self.style.SUCCESS("Tayyor. Login: admin1 / rektorat1 / fakultet1 / taminot1 / ombor1, parol: demo12345"))
