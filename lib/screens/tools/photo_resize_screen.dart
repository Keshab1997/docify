import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/image_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class PhotoResizeScreen extends StatefulWidget {
  const PhotoResizeScreen({super.key});

  @override
  State<PhotoResizeScreen> createState() => _PhotoResizeScreenState();
}

class _PhotoResizeScreenState extends State<PhotoResizeScreen> {
  File? _input;
  File? _output;
  int _targetKB = 100;
  bool _processing = false;

  final _kbOptions = [20, 50, 100, 200];
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  Future<void> _pick() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
    ); // Uses Photo Picker on Android 13+
    if (x != null) setState(() => _input = File(x.path));
  }

  Future<void> _resize() async {
    if (_input == null) return;
    setState(() => _processing = true);
    try {
      final w = int.tryParse(_widthController.text);
      final h = int.tryParse(_heightController.text);
      final out = await ImageService.resizeToKB(
        inputFile: _input!,
        targetKB: _targetKB,
        targetWidth: w,
        targetHeight: h,
      );
      final saved = await StorageService.saveToMyDocuments(out);
      setState(() => _output = saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resized to ${(saved.lengthSync() / 1024).toStringAsFixed(1)} KB',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Resize',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.photoResizeCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Main feature: Resize to exact KB for job forms. All processing on device, no upload.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _input == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40),
                          SizedBox(height: 8),
                          Text('Tap to pick photo (Photo Picker)'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_input!, fit: BoxFit.contain),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Target KB',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              children: [
                ..._kbOptions.map(
                  (kb) => ChoiceChip(
                    label: Text('${kb}KB'),
                    selected: _targetKB == kb,
                    onSelected: (_) => setState(() => _targetKB = kb),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Custom KB',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (v) {
                      final n = int.tryParse(v);
                      if (n != null) setState(() => _targetKB = n);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthController,
                    decoration: const InputDecoration(
                      labelText: 'Width px (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height px (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _resize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Resize to KB',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            if (_output != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Image.file(_output!, height: 150),
                    const SizedBox(height: 8),
                    Text(
                      'Output: ${(_output!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => SharePlus.instance.share(
                                ShareParams(files: [XFile(_output!.path)])),
                            child: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to My Documents'),
                              ),
                            ),
                            child: const Text('Saved'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
