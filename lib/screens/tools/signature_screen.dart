import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../services/storage_service.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  File? _output;
  bool _processing = false;
  int _targetKB = 50;

  Future<void> _save() async {
    if (_controller.isEmpty) return;
    setState(() => _processing = true);
    try {
      final data = await _controller.toPngBytes();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, 'sig_${DateTime.now().millisecondsSinceEpoch}.png');
      final file = File(path)..writeAsBytesSync(data);
      final resized = await ImageService.resizeToKB(inputFile: file, targetKB: _targetKB);
      final saved = await StorageService.saveToMyDocuments(resized);
      setState(() => _output = saved);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Signature')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            height: 250,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
            child: Signature(controller: _controller, backgroundColor: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(onPressed: () => _controller.clear(), child: const Text('Clear')),
                const SizedBox(width: 12),
                const Text('Target:'),
                const SizedBox(width: 8),
                DropdownButton<int>(value: _targetKB, items: [20, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('${e}KB'))).toList(), onChanged: (v) => setState(() => _targetKB = v!)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _processing ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton),
                  child: _processing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          if (_output != null) Padding(padding: const EdgeInsets.all(16), child: Image.file(_output!, height: 120)),
          const Padding(padding: EdgeInsets.all(16), child: Text('Draw signature, then resize to required KB. Background cleaned to white. All on-device.', style: TextStyle(fontSize: 11, color: AppColors.mutedText))),
        ],
      ),
    );
  }
}
