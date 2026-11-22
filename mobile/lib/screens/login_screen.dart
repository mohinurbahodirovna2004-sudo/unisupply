import 'package:flutter/material.dart';
import '../api.dart';
import '../ui.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController(), _p = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.login(_u.text.trim(), _p.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('UniSupply', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: kNavy)),
                  const SizedBox(height: 4),
                  const Text('Universitet ta’minotini boshqarish tizimi', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  TextField(controller: _u, decoration: const InputDecoration(labelText: 'Login'),
                      textInputAction: TextInputAction.next, autocorrect: false),
                  const SizedBox(height: 12),
                  TextField(controller: _p, obscureText: true, onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Parol')),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Kirish'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
