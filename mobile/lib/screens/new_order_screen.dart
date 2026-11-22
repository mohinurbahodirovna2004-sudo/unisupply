import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';
import 'scan_flow.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key, this.productId});
  final int? productId;
  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _qty = TextEditingController(text: '1'), _reason = TextEditingController();
  late final Future<List<List<dynamic>>> _data = Future.wait([
    Api.list('/api/products/'),
    if (Api.role == 'admin') Api.list('/api/departments/'),
  ]);
  int? _product, _dept;
  DateTime? _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _product = widget.productId;
  }

  Future<void> _submit() async {
    final q = int.tryParse(_qty.text);
    if (_product == null || q == null || q < 1) return snack(context, 'Mahsulot va miqdorni kiriting.');
    if (_reason.text.trim().isEmpty) return snack(context, 'Nima uchun kerakligini yozing.');
    if (Api.role == 'admin' && _dept == null) return snack(context, 'Bo‘limni tanlang.');
    setState(() => _busy = true);
    try {
      String two(int n) => n.toString().padLeft(2, '0');
      await Api.post('/api/orders/', {
        'product': _product, 'quantity': q, 'reason': _reason.text.trim(),
        if (_dept != null) 'department': _dept,
        if (_date != null) 'needed_by': '${_date!.year}-${two(_date!.month)}-${two(_date!.day)}',
      });
      if (!mounted) return;
      snack(context, 'Buyurtma yuborildi');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Yangi buyurtma')),
        body: FutureBuilder<List<List<dynamic>>>(
          future: _data,
          builder: (c, s) {
            if (s.hasError) return Center(child: Text('${s.error}'));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final products = s.data![0];
            final depts = s.data!.length > 1 ? s.data![1] : [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (depts.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Bo‘lim'),
                  items: [for (final d in depts) DropdownMenuItem(value: d['id'] as int, child: Text('${d['name']}'))],
                  onChanged: (v) => _dept = v,
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: products.any((p) => p['id'] == _product) ? _product : null,
                    decoration: const InputDecoration(labelText: 'Mahsulot'),
                    items: [
                      for (final p in products)
                        DropdownMenuItem(value: p['id'] as int, child: Text('${p['name']} (mavjud: ${p['available']} ${p['unit']})')),
                    ],
                    onChanged: (v) => setState(() => _product = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'QR-kod orqali tanlash',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final p = await scanProduct(context);
                    if (p == null || !mounted) return;
                    if (products.any((x) => x['id'] == p['id'])) {
                      setState(() => _product = p['id'] as int);
                    } else {
                      snack(context, 'Mahsulot ro‘yxatda topilmadi.');
                    }
                  },
                ),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Miqdor')),
              const SizedBox(height: 12),
              TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Nima uchun kerak?')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(_date == null ? 'Kerakli sana (ixtiyoriy)' : '${_date!.day}.${_date!.month}.${_date!.year}'),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context, initialDate: DateTime.now(),
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _busy ? null : _submit, child: const Text('Buyurtma yuborish')),
            ]);
          },
        ),
      );
}
