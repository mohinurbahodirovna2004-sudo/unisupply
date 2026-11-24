import 'package:flutter/material.dart';
import '../api.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'more_screen.dart';
import 'scan_flow.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'stock_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardScreen(), const OrdersScreen(), const StockScreen(), const NotificationsScreen(), const MoreScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Text('UniSupply · ${roleNames[Api.role] ?? ''}', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'QR-skaner',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => scanAndShow(context),
          ),
          IconButton(
            tooltip: 'Chiqish',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Api.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
          ),
        ],
      ),
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Bosh sahifa'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Buyurtmalar'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Ombor'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Xabarlar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Boshqaruv'),
        ],
      ),
    );
  }
}
