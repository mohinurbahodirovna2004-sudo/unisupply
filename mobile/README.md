# UniSupply — Flutter ilovasi (Android / iOS / Web)

Backend: `unisupply_backend.zip` dagi Django API.

## Ishga tushirish
    flutter create --org uz.unisupply --project-name unisupply .   # android/ios/web papkalarini yaratadi
    rm -f test/widget_test.dart                                    # standart test bu loyihaga mos emas
    flutter pub get
    flutter run --dart-define=API_URL=http://10.0.2.2:8000         # Android emulyator
    # iOS simulyator / Web uchun: --dart-define=API_URL=http://localhost:8000

Haqiqiy telefonda API_URL kompyuterning tarmoq IP'si yoki HTTPS domen bo‘lishi kerak.

## Android sozlamalari (`flutter create` dan keyin)
`android/app/src/main/AndroidManifest.xml` ga qo‘shing:
- `<uses-permission android:name="android.permission.INTERNET"/>` (`<application>` dan oldin)
- Faqat ishlab chiqishda, http uchun: `<application ... android:usesCleartextTraffic="true">`. Productionda HTTPS ishlating.

Veb uchun backend `CORS_ALLOW_ALL_ORIGINS` (DEBUG=1 da yoqilgan) bo‘lishi kerak.

## QR-skaner (mobile_scanner)
Yuqoridagi `flutter create` dan keyin kamera ruxsatini qo‘shing:
- **Android:** `AndroidManifest.xml` ga `<uses-permission android:name="android.permission.CAMERA"/>`; `minSdkVersion` kamida 21.
- **iOS:** `ios/Runner/Info.plist` ga `NSCameraUsageDescription` (masalan, "Mahsulot QR-kodini skanerlash uchun"); iOS 12+.
- Skaner telefon/planshetda ishlaydi. Emulyatorda kamera bo‘lmasa, klaviatura tugmasi orqali kodni qo‘lda kiriting.

Ishlatilishi: yuqori paneldagi skaner tugmasi (hamma ekranda) → mahsulot kartasi (omborda / band / mavjud). Fakultet va admin kartadan to‘g‘ridan-to‘g‘ri "Buyurtma berish"ga o‘tadi. Yangi buyurtma ekranida mahsulotni QR bilan tanlash mumkin. Kod hech bir mahsulotda topilmasa, admin/ta’minot/ombor xodimi uni mahsulotga biriktirishi mumkin. QR-kodlar backend adminida chop etiladi.

## Ekranlar va rollar
- **Kirish** (JWT, sessiya saqlanadi, token o‘zi yangilanadi)
- **Bosh sahifa:** kam zaxira ogohlantirishi; admin/rektorat/ta’minotga KPI va bo‘limlar bo‘yicha xarajat
- **Buyurtmalar:** holat bo‘yicha filtr; rolga qarab tugmalar — tekshirish/rad etish/bekor qilish (ta’minot), qabul qilish/topshirish (ombor); yangi buyurtma (fakultet, admin)
- **Ombor:** qidiruv, mavjud/band miqdor, kam qolganda sariq
- **Xabarlar:** buyurtma holati o‘zgarishlari

## Hali yo‘q
Firebase push, Excel yuklash tugmasi, mahsulot/bo‘lim boshqaruvi ekranlari.
