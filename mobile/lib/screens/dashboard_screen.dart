import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  static const _labels = {
    'new': 'Yangi', 'purchasing': 'Xarid jarayonida', 'ready': 'Tayyor',
    'delivered': 'Topshirilgan', 'rejected': 'Rad etilgan',
  };

  @override
  Widget build(BuildContext context) => Loader<Map<String, dynamic>>(
        load: () async {
          final low = await Api.list('/api/products/low_stock/');
          Map<String, dynamic>? sum;
          if (['admin', 'leader', 'supply'].contains(Api.role)) {
            sum = Map<String, dynamic>.from(await Api.get('/api/reports/summary/'));
          }
          return {'low': low, 'sum': sum};
        },
        builder: (c, d, reload) {
          final low = d['low'] as List;
          final sum = d['sum'] as Map<String, dynamic>?;
          final spend = (sum?['spend_by_department'] as List?) ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (sum != null) ...[
              Wrap(spacing: 10, runSpacing: 10, children: [
                _kpi('Mahsulotlar', '${sum['products']}', kNavy),
                _kpi('Kam zaxira', '${sum['low_stock']}', const Color(0xFFB7791F)),
                for (final e in (sum['orders_by_status'] as Map).entries)
                  _kpi(_labels[e.key] ?? '${e.key}', '${e.value}', statusColor('${e.key}')),
              ]),
              const SizedBox(height: 20),
              const Text('Xarajatlar (bo‘limlar kesimida)', style: TextStyle(fontWeight: FontWeight.w600)),
              for (final s in spend)
                ListTile(
                  dense: true,
                  title: Text('${s['department']}'),
                  trailing: Text(money(num.tryParse('${s['total']}') ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              if (spend.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Hozircha xarajat yo‘q.')),
              const SizedBox(height: 20),
            ],
            const Text('Ogohlantirishlar', style: TextStyle(fontWeight: FontWeight.w600)),
            if (low.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Zaxiralar yetarli.')),
            for (final p in low)
              ListTile(
                dense: true,
                leading: const Icon(Icons.warning_amber, color: Color(0xFFB7791F)),
                title: Text('${p['name']}'),
                subtitle: Text('Mavjud: ${p['available']} ${p['unit']} (minimum ${p['min_stock']})'),
              ),
          ]);
        },
      );

  Widget _kpi(String label, String value, Color color) => Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      );
}
