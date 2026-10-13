import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'not_xray_screen.dart';
import 'tooth_crop_screen.dart';
import 'xray_result_screen.dart';

/// X-ray scan: one photo, checked by the mode's X-ray model
/// (chest: Normal / Pneumonia; bone: No fracture / Fracture).
/// Before the model runs, a grayscale check makes sure the photo
/// actually looks like an X-ray — X-rays are black-and-white, so a
/// coloured photo is rejected instead of being forced into a class.
class XrayScanScreen extends StatefulWidget {
  final ScanMode mode;

  const XrayScanScreen({super.key, this.mode = ScanMode.xray});

  @override
  State<XrayScanScreen> createState() => _XrayScanScreenState();
}

class _XrayScanScreenState extends State<XrayScanScreen> {
  File? _image;
  bool _analyzing = false;
  final _picker = ImagePicker();
  final _model = SkinModelService();

  /// Mean saturation above which a photo is too coloured to be an
  /// X-ray. Calibrated on measured data: dataset X-ray images score
  /// 0.000 (pure grayscale) and photos of an X-ray film stay low,
  /// while skin photos score 0.135+, a hand/arm 0.2-0.46 and a room
  /// wall 0.19 - so 0.10 separates the two groups with margin.
  static const double _maxSaturation = 0.10;

  String get _title => switch (widget.mode) {
        ScanMode.bone => 'Bone X-Ray Scan',
        ScanMode.knee => 'Knee X-Ray Scan',
        ScanMode.dental => 'Dental X-Ray Scan',
        _ => 'Chest X-Ray Scan',
      };

  String get _subject => switch (widget.mode) {
        ScanMode.bone => 'a bone X-ray',
        ScanMode.knee => 'a knee X-ray',
        ScanMode.dental => 'a dental X-ray',
        _ => 'a chest X-ray',
      };

  String get _tip => switch (widget.mode) {
        ScanMode.bone =>
          'Tip: use the digital X-ray image from your report, or '
              'photograph the X-ray film against a white light. The '
              'model screens for fractures only (No fracture / '
              'Fracture) and runs fully on-device.',
        ScanMode.knee =>
          'Tip: use the digital X-ray image from your report, or '
              'photograph the X-ray film against a white light. The '
              'model screens for osteoarthritis signs only (Healthy '
              '/ Mild / Severe) and runs fully on-device.',
        ScanMode.dental =>
          'Tip: use the full panoramic (OPG) dental X-ray image. '
              'On the next step you will frame ONE tooth in a box, '
              'and the model checks that tooth (Healthy teeth / '
              'Cavity / Impacted tooth). One tooth at a time gives '
              'a much better check than the whole X-ray at once.',
        _ =>
          'Tip: use the digital X-ray image from your report, or '
              'photograph the X-ray film against a white light. The '
              'model screens for pneumonia signs only (Normal / '
              'Pneumonia) and runs fully on-device.',
      };

  @override
  void initState() {
    super.initState();
    _model.load(widget.mode);
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  /// Average (max-min)/max across pixels: 0 for pure grayscale.
  double _meanSaturation(img.Image im) {
    var sum = 0.0;
    var n = 0;
    for (var y = 0; y < im.height; y += 2) {
      for (var x = 0; x < im.width; x += 2) {
        final p = im.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        final mx = [r, g, b].reduce((a, b) => a > b ? a : b);
        final mn = [r, g, b].reduce((a, b) => a < b ? a : b);
        if (mx > 0) {
          sum += (mx - mn) / mx;
          n++;
        }
      }
    }
    return n == 0 ? 0 : sum / n;
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _analyzing = true);
    try {
      final bytes = await _image!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Could not decode image');
      final small = img.copyResize(decoded, width: 224, height: 224);
      if (!mounted) return;
      if (_meanSaturation(small) > _maxSaturation) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  NotXrayScreen(image: _image!, subject: _subject)),
        );
        return;
      }
      if (widget.mode == ScanMode.dental) {
        final cropped = await Navigator.push<File>(
          context,
          MaterialPageRoute(
              builder: (_) => ToothCropScreen(image: _image!)),
        );
        if (cropped == null || !mounted) return;
        final dentalAnalysis =
            await _model.analyze(cropped, ScanMode.dental);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => XrayResultScreen(
                image: cropped,
                analysis: dentalAnalysis,
                mode: ScanMode.dental),
          ),
        );
        return;
      }
      final analysis = await _model.analyze(_image!, widget.mode);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => XrayResultScreen(
              image: _image!, analysis: analysis, mode: widget.mode),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomPaint(
              painter: _DashedBorderPainter(),
              child: Container(
                height: 320,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 60, color: AppTheme.muted),
                          SizedBox(height: 10),
                          Text('No image selected',
                              style: TextStyle(
                                  fontSize: 15, color: AppTheme.muted)),
                          SizedBox(height: 4),
                          Text('Take a photo of the X-ray or pick one from the gallery',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppTheme.muted)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_image!,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined,
                        color: AppTheme.accent),
                    label: const Text('Camera'),
                    style:
                        OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined,
                        color: AppTheme.accent),
                    label: const Text('Gallery'),
                    style:
                        OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: (_image == null || _analyzing) ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.analytics_outlined),
              label: Text(_analyzing ? 'Analyzing...' : 'Analyze X-Ray'),
            ),
            const SizedBox(height: 16),
            Text(
              _tip,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a rounded-rectangle dashed border (scanner-frame look).
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9AA7B8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);
    const dash = 9.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
