import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';

/// Dental flow step: the user frames ONE tooth of the panoramic
/// X-ray inside a movable box; the crop is what the dental model
/// was trained on (single-tooth images). Pops with the cropped
/// image as a temp [File], or null if the user backs out.
class ToothCropScreen extends StatefulWidget {
  final File image;

  const ToothCropScreen({super.key, required this.image});

  @override
  State<ToothCropScreen> createState() => _ToothCropScreenState();
}

class _ToothCropScreenState extends State<ToothCropScreen> {
  img.Image? _decoded;
  bool _working = false;

  /// Box centre as a fraction of the displayed image (0..1).
  Offset _centre = const Offset(0.5, 0.5);

  /// Box width as a fraction of the displayed image width.
  double _boxFrac = 0.34;

  /// Box height / width (teeth are taller than wide).
  static const double _aspect = 1.6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.image.readAsBytes();
    final d = img.decodeImage(bytes);
    if (mounted) setState(() => _decoded = d);
  }

  Future<void> _confirm(Rect imgRect, Size area) async {
    final decoded = _decoded;
    if (decoded == null) return;
    setState(() => _working = true);
    try {
      // Box in displayed-image pixels -> original image pixels.
      final scale = decoded.width / imgRect.width;
      final bw = _boxFrac * imgRect.width;
      final bh = bw * _aspect;
      final cx = imgRect.left + _centre.dx * imgRect.width;
      final cy = imgRect.top + _centre.dy * imgRect.height;
      var x0 = ((cx - bw / 2) * scale).round();
      var y0 = ((cy - bh / 2) * scale).round();
      var w = (bw * scale).round();
      var h = (bh * scale).round();
      x0 = x0.clamp(0, decoded.width - 16);
      y0 = y0.clamp(0, decoded.height - 16);
      w = w.clamp(16, decoded.width - x0);
      h = h.clamp(16, decoded.height - y0);
      final crop = img.copyCrop(decoded, x: x0, y: y0, width: w, height: h);
      final tmp = File(
          '${Directory.systemTemp.path}/tooth_${DateTime.now().millisecondsSinceEpoch}.png');
      await tmp.writeAsBytes(img.encodePng(crop));
      if (mounted) Navigator.pop(context, tmp);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select One Tooth')),
      body: _decoded == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Fit ONE tooth inside the box. Drag the box to '
                    'move it, and use the slider to make it bigger '
                    'or smaller. The clearer and larger the tooth, '
                    'the better the check.',
                    style: TextStyle(
                        fontSize: 13.5, height: 1.4, color: AppTheme.muted),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final area =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      // Contain-fit rect of the image inside the area.
                      final imgAspect = _decoded!.width / _decoded!.height;
                      var dw = area.width;
                      var dh = dw / imgAspect;
                      if (dh > area.height) {
                        dh = area.height;
                        dw = dh * imgAspect;
                      }
                      final imgRect = Rect.fromLTWH(
                          (area.width - dw) / 2, (area.height - dh) / 2, dw, dh);
                      final bw = _boxFrac * imgRect.width;
                      final bh = bw * _aspect;
                      final cx = imgRect.left + _centre.dx * imgRect.width;
                      final cy = imgRect.top + _centre.dy * imgRect.height;
                      final boxRect = Rect.fromCenter(
                          center: Offset(cx, cy), width: bw, height: bh);
                      return Stack(
                        children: [
                          Positioned.fromRect(
                            rect: imgRect,
                            child: Image.file(widget.image, fit: BoxFit.fill),
                          ),
                          Positioned.fromRect(
                            rect: boxRect,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                setState(() {
                                  _centre = Offset(
                                    (_centre.dx + d.delta.dx / imgRect.width)
                                        .clamp(0.0, 1.0),
                                    (_centre.dy + d.delta.dy / imgRect.height)
                                        .clamp(0.0, 1.0),
                                  );
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppTheme.accent, width: 2.5),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.accent.withOpacity(0.12),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 8,
                            child: Row(
                              children: [
                                const Icon(Icons.zoom_out,
                                    size: 20, color: AppTheme.muted),
                                Expanded(
                                  child: Slider(
                                    value: _boxFrac,
                                    min: 0.15,
                                    max: 0.6,
                                    onChanged: (v) =>
                                        setState(() => _boxFrac = v),
                                  ),
                                ),
                                const Icon(Icons.zoom_in,
                                    size: 20, color: AppTheme.muted),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 52,
                            child: ElevatedButton.icon(
                              onPressed: _working
                                  ? null
                                  : () => _confirm(imgRect, area),
                              icon: _working
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check),
                              label: const Text('Check This Tooth'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
