import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';
import 'new_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _filters = {
    '': 'Hammasi', 'new': 'Yangi', 'purchasing': 'Xarid', 'ready': 'Tayyor',
    'delivered': 'Topshirilgan', 'rejected': 'Rad etilgan',
  };
  String _status = '';
  Key _key = UniqueKey();

  bool get _canCreate => ['faculty', 'admin'].contains(Api.role);
  void _refresh() => setState(() => _key = UniqueKey());

  Future<String?> _askNote(String title) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(labelText: 'Sabab')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: const Text('Yuborish')),
        ],
      ),
    );
  }

  Future<void> _act(Map o, String action, {String? noteTitle}) async {
    String? note;
    if (noteTitle != null) {
      note = await _askNote(noteTitle);
      if (note == null) return;
    }
    try {
      await Api.post('/api/orders/${o['id']}/$action/', {if (note != null) 'note': note});
      if (!mounted) return;
      snack(context, 'Bajarildi');
      _refresh();
    } catch (e) {
      if (mounted) snack(context, '$e');
    }
  }

  List<Widget> _buttons(Map o) {
    final r = Api.role, s = o['status'];
    Widget b(String t, String a, {String? note, bool danger = false}) => danger
        ? OutlinedButton(onPressed: () => _act(o, a, noteTitle: note), child: Text(t))
        : FilledButton(onPressed: () => _act(o, a, noteTitle: note), child: Text(t));
    return [
      if (r == 'supply' && s == 'new') b('Tekshirish va tasdiqlash', 'review'),
      if ((r == 'supply' || r == 'leader') && s == 'new') b('Rad etish', 'reject', note: 'Rad etish sababi', danger: true),
      if (r == 'warehouse' && s == 'purchasing') b('Xaridni qabul qilish (${o['purchase_qty']})', 'receive'),
      if (r == 'warehouse' && s == 'ready') b('Bo‘limga topshirish', 'deliver'),
      if ((r == 'supply' || r == 'admin') && (s == 'purchasing' || s == 'ready'))
        b('Bekor qilish', 'cancel', note: 'Bekor qilish sababi', danger: true),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: _canCreate
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('Yangi buyurtma'),
                onPressed: () async {
                  final ok = await Navigator.of(context)
                      .push<bool>(MaterialPageRoute(builder: (_) => const NewOrderScreen()));
                  if (ok == true) _refresh();
                },
              )
            : null,
        body: Column(children: [
          SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final e in _filters.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _status == e.key,
                    onSelected: (_) => setState(() {
                      _status = e.key;
                      _key = UniqueKey();
                    }),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: Loader<List<dynamic>>(
              key: _key,
              load: () => Api.list('/api/orders/${_status.isEmpty ? '' : '?status=$_status'}'),
              builder: (c, orders, reload) => orders.isEmpty
                  ? ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Text('Buyurtmalar yo‘q.', textAlign: TextAlign.center))])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                      itemCount: orders.length,
                      itemBuilder: (_, i) => _card(orders[i] as Map),
                    ),
            ),
          ),
        ]),
      );

  Widget _card(Map o) {
    final color = statusColor('${o['status']}');
    final buttons = _buttons(o);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${o['number']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Chip(
              label: Text('${o['status_label']}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ]),
          Text('${o['product_name']} × ${o['quantity']}', style: const TextStyle(fontSize: 16)),
          Text('${o['department_name']}', style: const TextStyle(color: Colors.black54)),
          Text('${o['reason']}'),
          if ('${o['note']}'.isNotEmpty) Text('${o['note']}', style: TextStyle(color: color)),
          if (buttons.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Wrap(spacing: 8, runSpacing: 8, children: buttons)),
        ]),
      ),
    );
  }
}
