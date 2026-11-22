import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'ui.dart';

void main() => runApp(const UniSupplyApp());

class UniSupplyApp extends StatelessWidget {
  const UniSupplyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'UniSupply',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kNavy),
          appBarTheme: const AppBarTheme(backgroundColor: kNavy, foregroundColor: Colors.white),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: FutureBuilder<bool>(
          future: Api.restore(),
          builder: (c, s) {
            if (!s.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            return s.data! ? const HomeShell() : const LoginScreen();
          },
        ),
      );
}
