import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api.dart';
import '../ui.dart';

class _F {
  const _F(this.label, {this.init = '', this.number = false, this.secret = false});
  final String label, init;
  final bool number, secret;
}

Future<List<String>?> _ask(BuildContext context, String title, List<_F> fields) {
  final ctls = [for (final f in fields) TextEditingController(text: f.init)];
  return showDialog<List<String>>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: ctls[i],
                obscureText: fields[i].secret,
                keyboardType: fields[i].number ? TextInputType.number : null,
                decoration: InputDecoration(labelText: fields[i].label),
              ),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bekor')),
        FilledButton(
          onPressed: () => Navigator.pop(c, [for (var i = 0; i < ctls.length; i++) fields[i].secret ? ctls[i].text : ctls[i].text.trim()]),
          child: const Text('Saqlash'),
        ),
      ],
    ),
  );
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  bool _has(List<String> roles) => roles.contains(Api.role);

  Future<void> _run(BuildContext c, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      if (c.mounted) snack(c, '$e');
    }
  }

  Future<void> _changePassword(BuildContext c) => _run(c, () async {
        final v = await _ask(c, 'Parolni o‘zgartirish',
            const [_F('Eski parol', secret: true), _F('Yangi parol (kamida 8 belgi)', secret: true)]);
        if (v == null) return;
        await Api.post('/api/auth/change_password/', {'old_password': v[0], 'new_password': v[1]});
        if (c.mounted) snack(c, 'Parol o‘zgartirildi');
      });

  Future<void> _export(BuildContext c, String kind) => _run(c, () async {
        final bytes = await Api.getBytes('/api/reports/export/?kind=$kind');
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/unisupply_$kind.xlsx');
        await f.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(f.path)], text: 'UniSupply hisoboti');
      });

  Future<void> _addProduct(BuildContext c) => _run(c, () async {
        final v = await _ask(c, 'Yangi mahsulot', const [
          _F('Nomi'), _F('Turi'), _F('O‘lchov birligi', init: 'dona'),
          _F('Narxi (soʻm)', number: true), _F('Minimal zaxira', init: '0', number: true),
        ]);
        if (v == null) return;
        if (v[0].isEmpty) throw ApiException('Mahsulot nomini kiriting.');
        await Api.post('/api/products/', {
          'name': v[0], 'kind': v[1], 'unit': v[2].isEmpty ? 'dona' : v[2],
          'price': v[3].isEmpty ? '0' : v[3], 'min_stock': int.tryParse(v[4]) ?? 0,
        });
        if (c.mounted) snack(c, 'Mahsulot qo‘shildi (kod avtomatik berildi)');
      });

  Future<void> _addDept(BuildContext c) => _run(c, () async {
        final v = await _ask(c, 'Yangi bo‘lim', const [_F('Bo‘lim nomi')]);
        if (v == null || v[0].isEmpty) return;
        await Api.post('/api/departments/', {'name': v[0]});
        if (c.mounted) snack(c, 'Bo‘lim qo‘shildi');
      });

  Future<void> _stockIn(BuildContext c) => _run(c, () async {
        final ps = await Api.list('/api/products/?ordering=name');
        if (!c.mounted) return;
        int? sel;
        final qty = TextEditingController();
        final ok = await showDialog<bool>(
          context: c,
          builder: (d) => AlertDialog(
            title: const Text('Omborga kirim'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mahsulot'),
                items: [for (final p in ps) DropdownMenuItem(value: p['id'] as int, child: Text('${p['name']}'))],
                onChanged: (v) => sel = v,
              ),
              const SizedBox(height: 8),
              TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Miqdor')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Bekor')),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Kirim qilish')),
            ],
          ),
        );
        if (ok != true) return;
        final q = int.tryParse(qty.text);
        if (sel == null || q == null || q < 1) throw ApiException('Mahsulot va miqdorni kiriting.');
        await Api.post('/api/products/$sel/stock_in/', {'quantity': q});
        if (c.mounted) snack(c, 'Kirim qayd etildi');
      });

  Widget _tile(IconData i, String t, VoidCallback f) => ListTile(leading: Icon(i), title: Text(t), onTap: f);

  @override
  Widget build(BuildContext c) => ListView(children: [
        ListTile(
          leading: const CircleAvatar(backgroundColor: kNavy, child: Icon(Icons.person, color: Colors.white)),
          title: Text('${Api.me['username']}'),
          subtitle: Text(roleNames[Api.role] ?? ''),
        ),
        const Divider(),
        _tile(Icons.lock_reset, 'Parolni o‘zgartirish', () => _changePassword(c)),
        if (_has(['admin', 'warehouse'])) _tile(Icons.move_to_inbox_outlined, 'Omborga kirim', () => _stockIn(c)),
        if (_has(['admin', 'supply', 'warehouse'])) _tile(Icons.add_box_outlined, 'Yangi mahsulot', () => _addProduct(c)),
        if (_has(['admin'])) _tile(Icons.apartment_outlined, 'Yangi bo‘lim', () => _addDept(c)),
        if (_has(['admin', 'leader', 'supply'])) _tile(Icons.table_chart_outlined, 'Buyurtmalar hisoboti (Excel)', () => _export(c, 'orders')),
        if (_has(['admin', 'leader', 'supply', 'warehouse'])) _tile(Icons.inventory_outlined, 'Ombor hisoboti (Excel)', () => _export(c, 'stock')),
      ]);
}
