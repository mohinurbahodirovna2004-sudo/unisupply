# UniSupply — backend (Django REST Framework + PostgreSQL)

## Ishga tushirish
    pip install -r requirements.txt
    python manage.py migrate
    python manage.py seed_demo          # demo foydalanuvchilar (parol: demo12345)
    python manage.py runserver
    python manage.py test               # ish jarayoni testi

Docker + PostgreSQL: `docker compose up --build` (so‘ng `docker compose exec api python manage.py seed_demo`).

## API (JWT: `Authorization: Bearer <access>`)
| Yo‘l | Vazifa |
|---|---|
| POST /api/auth/login/ , /refresh/ | kirish (username, password) |
| GET /api/me/ | joriy foydalanuvchi va roli |
| /api/departments/ /products/ /suppliers/ | CRUD (yozish rollarga bog‘liq) |
| POST /api/products/{id}/stock_in/ {quantity} | ombor: buyurtmasiz kirim |
| POST /api/auth/change_password/ | parolni almashtirish |
| GET /api/products/by_barcode/?code=… | QR/shtrix-kod bo‘yicha mahsulot (404 — topilmadi) |
| GET /api/products/low_stock/ | kam qolgan zaxira |
| GET,POST /api/orders/ | buyurtmalar (fakultet faqat o‘zinikini ko‘radi) |
| POST /api/orders/{id}/review/ | ta’minot: tekshirish → tayyor yoki xarid |
| POST /api/orders/{id}/reject/ {note} | rad etish |
| POST /api/orders/{id}/receive/ | ombor: xaridni qabul qilish (kirim) |
| POST /api/orders/{id}/deliver/ | ombor: bo‘limga topshirish (chiqim) |
| POST /api/orders/{id}/cancel/ {note} | ta’minot: xarid/tayyor buyurtmani bekor qilish, zaxira bo‘shatiladi |
| GET /api/reports/export/?kind=orders&from=&to= | Excel (.xlsx); `kind=stock` — ombor holati |
| GET /api/movements/ | kirim-chiqim jurnali |
| GET /api/notifications/ , POST read_all | bildirishnomalar |
| GET /api/reports/summary/ | xarajat va holat ko‘rsatkichlari |

## QR-kodlar
Har bir mahsulotga saqlanganda `UNI-000123` ko‘rinishidagi kod avtomatik beriladi. Django admin (`/admin/` → Products) da har mahsulot yonida QR ko‘rinadi — chop etib mahsulot yoki javonga yopishtiring. Eski bazadagi mahsulotlar uchun: `python manage.py gen_barcodes`. Tayyor shtrix-kodli (EAN) mahsulotlarda kodni ilova orqali almashtirish mumkin.

## Zaxirani band qilish
`Product.reserved` — tasdiqlangan buyurtmalar uchun band qilingan miqdor; `available = stock − reserved`. Ikkita buyurtma bir xil mahsulotni ikki marta ololmaydi.
Excel yuklab olish uchun so‘rovga `Authorization: Bearer <access>` sarlavhasi kerak.

## Keyingi bosqichlar
Flutter ilova (shu API ustida), FCM push (Notification modeli tayyor), PDF eksport, prognoz.

## Haqiqiy ishga o‘tish
Render → Environment'da `ADMIN_USERNAME`, `ADMIN_PASSWORD` qo‘shing, `SEED_DEMO` ni `0` qiling (demo foydalanuvchilar yaratilmaydi; mavjudlarini admin panelidan o‘chiring). Foydalanuvchilarni `/admin/` orqali yarating, rolini tanlang.
