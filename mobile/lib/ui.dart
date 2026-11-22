import 'package:flutter/material.dart';

const kNavy = Color(0xFF0F2A52);

Color statusColor(String s) => switch (s) {
      'delivered' => const Color(0xFF1F9D55),
      'rejected' => const Color(0xFFC0392B),
      'new' => const Color(0xFF2457C5),
      _ => const Color(0xFFB7791F),
    };

String money(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b soʻm';
}

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

/// Ma’lumotni yuklaydi: kutish, xato (qayta urinish) va tortib yangilash bilan.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _f = widget.load();
  void _reload() => setState(() => _f = widget.load());

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return ListView(padding: const EdgeInsets.all(24), children: [
              Text('${s.error}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Center(child: FilledButton(onPressed: _reload, child: const Text('Qayta urinish'))),
            ]);
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _f;
            },
            child: widget.builder(c, s.data as T, _reload),
          );
        },
      );
}
