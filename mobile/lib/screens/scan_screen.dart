import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Kamerani ochadi va topilgan kodni (String) qaytaradi. Kamera bo‘lmasa — qo‘lda kiritish.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ctl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;

  void _finish(String code) {
    if (_done || code.trim().isEmpty) return;
    _done = true;
    Navigator.pop(context, code.trim());
  }

  Future<void> _manual() async {
    final ctl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kodni kiriting'),
        content: TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(labelText: 'Masalan: UNI-000001')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Qidirish')),
        ],
      ),
    );
    if (v != null) _finish(v);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('QR-kodni skanerlang'),
          actions: [
            IconButton(tooltip: 'Chiroq', icon: const Icon(Icons.flashlight_on_outlined), onPressed: () => _ctl.toggleTorch()),
            IconButton(tooltip: 'Qo‘lda kiritish', icon: const Icon(Icons.keyboard_outlined), onPressed: _manual),
          ],
        ),
        body: Stack(children: [
          MobileScanner(
            controller: _ctl,
            onDetect: (cap) {
              for (final b in cap.barcodes) {
                final v = b.rawValue;
                if (v != null) return _finish(v);
              }
            },
            errorBuilder: (c, e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Kamera ishlamayapti yoki ruxsat berilmagan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _manual, child: const Text('Kodni qo‘lda kiritish')),
                ]),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Positioned(
            bottom: 32, left: 0, right: 0,
            child: Text('Kodni ramka ichiga joylang', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ),
        ]),
      );
}
