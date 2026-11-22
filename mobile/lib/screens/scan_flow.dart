import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';
import 'new_order_screen.dart';
import 'scan_screen.dart';

const _staff = ['admin', 'supply', 'warehouse'];

/// Kodni skanerlaydi va mahsulotni qaytaradi. Topilmasa xabar beradi
/// (xodimlarga kodni mahsulotga biriktirishni taklif qiladi) va null qaytaradi.
Future<Map<String, dynamic>?> scanProduct(BuildContext context, {bool offerAssign = false}) async {
  final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
  if (code == null || !context.mounted) return null;
  try {
    return Map<String, dynamic>.from(await Api.get('/api/products/by_barcode/?code=${Uri.encodeQueryComponent(code)}'));
  } on ApiException catch (e) {
    if (!context.mounted) return null;
    if (e.status == 404 && offerAssign && _staff.contains(Api.role)) {
      await _assign(context, code);
    } else {
      snack(context, e.message);
    }
    return null;
  }
}

/// Skanerlash → mahsulot kartasi (qoldiq, band, mavjud; fakultet uchun "Buyurtma berish").
Future<void> scanAndShow(BuildContext context) async {
  final p = await scanProduct(context, offerAssign: true);
  if (p == null || !context.mounted) return;
  final canOrder = ['faculty', 'admin'].contains(Api.role);
  final low = p['is_low'] == true;
  const amber = Color(0xFFB7791F);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p['name']}', style: Theme.of(c).textTheme.titleLarge),
        Text('${p['kind']} · ${p['unit']} · kod: ${p['barcode']}'),
        const SizedBox(height: 14),
        Row(children: [
          _stat('Omborda', '${p['stock']}'),
          _stat('Band', '${p['reserved']}'),
          _stat('Mavjud', '${p['available']}', color: low ? amber : null),
        ]),
        if (low) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Zaxira kam — minimum ${p['min_stock']}', style: const TextStyle(color: amber))),
        if (canOrder)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Buyurtma berish'),
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewOrderScreen(productId: p['id'] as int)));
                },
              ),
            ),
          ),
      ]),
    ),
  );
}

Widget _stat(String label, String value, {Color? color}) => Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
        Text(label),
      ]),
    );

Future<void> _assign(BuildContext context, String code) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Kod topilmadi'),
      content: Text('"$code" kodi hech bir mahsulotga biriktirilmagan. Mahsulotga biriktirasizmi? (Mahsulotning oldingi kodi almashtiriladi.)'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Yo‘q')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Biriktirish')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    final all = await Api.list('/api/products/?ordering=name');
    if (!context.mounted) return;
    final picked = await showDialog<Map>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Mahsulotni tanlang'),
        children: [
          for (final p in all)
            SimpleDialogOption(onPressed: () => Navigator.pop(c, p), child: Text('${p['name']}')),
        ],
      ),
    );
    if (picked == null) return;
    await Api.patch('/api/products/${picked['id']}/', {'barcode': code});
    if (context.mounted) snack(context, 'Kod biriktirildi: ${picked['name']}');
  } catch (e) {
    if (context.mounted) snack(context, '$e');
  }
}
