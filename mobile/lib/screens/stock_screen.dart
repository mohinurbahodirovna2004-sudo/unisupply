import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Mahsulot qidirish', isDense: true),
            onSubmitted: (v) => setState(() => _q = v.trim()),
          ),
        ),
        Expanded(
          child: Loader<List<dynamic>>(
            key: ValueKey(_q),
            load: () => Api.list('/api/products/?search=${Uri.encodeQueryComponent(_q)}'),
            builder: (c, items, reload) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = items[i] as Map;
                final low = p['is_low'] == true;
                final min = (p['min_stock'] as int) * 4;
                final ratio = min == 0 ? 1.0 : ((p['available'] as int) / min).clamp(0.0, 1.0);
                return ListTile(
                  title: Text('${p['name']}'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      LinearProgressIndicator(value: ratio, color: low ? const Color(0xFFB7791F) : kNavy),
                      const SizedBox(height: 4),
                      Text('${p['kind']} · omborda ${p['stock']}, band ${p['reserved']}'),
                    ]),
                  ),
                  trailing: Text('${p['available']} ${p['unit']}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: low ? const Color(0xFFB7791F) : null)),
                );
              },
            ),
          ),
        ),
      ]);
}
