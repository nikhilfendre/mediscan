import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/lab_report_service.dart';
import '../theme/app_theme.dart';
import 'lab_result_screen.dart';

/// Lab Report flow: pick a photo of a printed blood report; the
/// values are read on-device (ML Kit OCR) and compared with their
/// reference ranges - see [LabReportService].
class LabScanScreen extends StatefulWidget {
  const LabScanScreen({super.key});

  @override
  State<LabScanScreen> createState() => _LabScanScreenState();
}

class _LabScanScreenState extends State<LabScanScreen> {
  final _picker = ImagePicker();
  final _service = LabReportService();
  File? _image;
  bool _working = false;
  bool _notRead = false;

  Future<void> _pick(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 95);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _notRead = false;
    });
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _working = true;
      _notRead = false;
    });
    try {
      final results = await _service.analyze(_image!);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _notRead = true);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LabResultScreen(image: _image!, results: results),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Report Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Check a printed blood report (CBC, blood sugar, '
              'cholesterol and more). The app reads the values from '
              'the photo and marks the ones outside their reference '
              'range.',
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: const Color(0xFFD9E0EC)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _image == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 56, color: AppTheme.muted),
                          SizedBox(height: 10),
                          Text('No report selected',
                              style: TextStyle(color: AppTheme.muted)),
                        ],
                      ),
                    )
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _working ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _working ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: (_image == null || _working) ? null : _analyze,
              icon: _working
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_working ? 'Reading report...' : 'Read Report'),
            ),
            if (_notRead) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: const Text(
                  'No test values could be read from this photo. '
                  'For best results: use a printed report (not '
                  'handwritten), fill the frame with the report, keep '
                  'it straight and in good light, and avoid glare '
                  'or shadows.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF7A5200)),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const DisclaimerStrip(
              text:
                  'This reads values from a photo for information only. Always confirm with the original lab report and your doctor - reference ranges differ between labs.',
            ),
          ],
        ),
      ),
    );
  }
}
