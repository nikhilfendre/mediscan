import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'no_problem_screen.dart';
import 'not_skin_screen.dart';
import 'result_screen.dart';

/// One scan for everything: the photo is checked by BOTH on-device
/// models — the 32-condition common-problems model and the 7-condition
/// lesion model — and both results are shown on one screen.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _analyzing = false;
  final _picker = ImagePicker();
  final _model = SkinModelService();

  @override
  void initState() {
    super.initState();
    // Warm up both models while the user picks a photo.
    _model.load(ScanMode.clinical);
    _model.load(ScanMode.dermoscopy);
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _analyzing = true);
    try {
      final clinical = await _model.analyze(_image!, ScanMode.clinical);
      final dermoscopy = await _model.analyze(_image!, ScanMode.dermoscopy);
      if (!mounted) return;
      // Stage-1 gate (colour): never show a disease prediction for a
      // non-skin photo. A model counts only if its own gate passed.
      if (!clinical.isSkin && !dermoscopy.isSkin) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotSkinScreen(
              image: _image!,
              skinRatio: math.max(clinical.skinRatio, dermoscopy.skinRatio),
              clinical: true,
            ),
          ),
        );
        return;
      }
      final maxSkinRatio =
          math.max(clinical.skinRatio, dermoscopy.skinRatio);

      // Winner selection (measured on the sample set + real phone
      // photos): the clinical model is the authority for normal
      // camera photos — on such photos the lesion model fires
      // confident but WRONG answers (it was trained only on
      // dermoscopic images). The lesion model may overrule only on a
      // near-certain dermoscopic slam-dunk (top >= 0.98 while the
      // clinical model is uncertain) — e.g. vascular lesion at 1.00.
      final ScanMode winnerMode;
      if (clinical.isSkin && dermoscopy.isSkin) {
        winnerMode =
            (dermoscopy.topConfidence >= 0.98 && clinical.isUncertain)
                ? ScanMode.dermoscopy
                : ScanMode.clinical;
      } else {
        winnerMode =
            clinical.isSkin ? ScanMode.clinical : ScanMode.dermoscopy;
      }
      final winner =
          winnerMode == ScanMode.clinical ? clinical : dermoscopy;

      // Abstention gates: a screening app must be able to say "no
      // answer" instead of inventing a disease.
      if (winner.isUncertain) {
        // (a) A beige wall / wooden table has skin-LIKE colours, so
        // the colour gate alone cannot reject it — but such a scene
        // is only partly skin-coloured. Partly-skin + no confident
        // reading = not a readable skin photo.
        if (maxSkinRatio < 0.60) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotSkinScreen(
                image: _image!,
                skinRatio: maxSkinRatio,
                clinical: true,
                unclear: true,
              ),
            ),
          );
          return;
        }
        // (b) The photo is clearly skin (coverage is high) but
        // neither model can find a clear problem in it — e.g. a
        // healthy hand. The models know only diseases, so without
        // this gate they would be forced to invent one. The lesion
        // model being certain is enough to still show a result
        // (it may be seeing a real lesion the camera model missed).
        if (winnerMode == ScanMode.clinical && dermoscopy.isUncertain) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoProblemScreen(image: _image!),
            ),
          );
          return;
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: _image!,
            clinical: clinical.isSkin ? clinical : null,
            dermoscopy: dermoscopy.isSkin ? dermoscopy : null,
            winner: winnerMode,
          ),
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
      appBar: AppBar(title: const Text('Skin Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo preview inside a dashed frame, like a scanner target.
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
                          Icon(Icons.add_a_photo_outlined,
                              size: 60, color: AppTheme.muted),
                          SizedBox(height: 10),
                          Text('No image selected',
                              style: TextStyle(
                                  fontSize: 15, color: AppTheme.muted)),
                          SizedBox(height: 4),
                          Text('Take a photo or pick one from the gallery',
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
              label: Text(_analyzing ? 'Analyzing...' : 'Analyze with AI'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: take a clear, well-lit photo of the affected skin, '
              'scalp or nails. One photo is checked for common skin '
              'problems (32) and skin lesions (7). Analysis runs '
              'on-device — your photo never leaves the phone.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.muted),
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
