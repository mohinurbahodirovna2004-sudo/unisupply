import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Loader<List<dynamic>>(
        load: () => Api.list('/api/notifications/'),
        builder: (c, items, reload) => ListView(children: [
          if (items.any((n) => n['is_read'] == false))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await Api.post('/api/notifications/read_all/');
                  reload();
                },
                child: const Text('Hammasini o‘qilgan deb belgilash'),
              ),
            ),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Xabarlar yo‘q.'))),
          for (final n in items)
            ListTile(
              leading: Icon(n['is_read'] == true ? Icons.notifications_none : Icons.notifications_active,
                  color: n['is_read'] == true ? null : kNavy),
              title: Text('${n['text']}', style: TextStyle(fontWeight: n['is_read'] == true ? null : FontWeight.w600)),
              subtitle: Text('${n['created_at']}'.substring(0, 16).replaceFirst('T', ' ')),
            ),
        ]),
      );
}
