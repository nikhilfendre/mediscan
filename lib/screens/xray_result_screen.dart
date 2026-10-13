import 'dart:io';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'report_screen.dart';

/// Chest X-ray result: one screening answer (Normal / Pneumonia)
/// with confidence, the low-confidence warning when the model is
/// unsure, a full report, and save-to-history.
class XrayResultScreen extends StatefulWidget {
  final File image;
  final SkinAnalysis analysis;
  final ScanMode mode;

  const XrayResultScreen(
      {super.key,
      required this.image,
      required this.analysis,
      required this.mode});

  @override
  State<XrayResultScreen> createState() => _XrayResultScreenState();
}

class _XrayResultScreenState extends State<XrayResultScreen> {
  bool _saved = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final store = FirestoreService();
      final url = await store.uploadScanImage(widget.image, scanId);
      final localPath =
          await store.saveScanImageLocally(widget.image, scanId);
      final a = widget.analysis;
      final top = a.results.first;
      await store.saveScan(
        label: top.key,
        confidence: top.value,
        top3: a.results.take(3).toList(),
        imageUrl: url,
        localImagePath: localPath,
        modelType: widget.mode.storageKey,
      );
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to history ✓')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _confidenceColor(double p) {
    if (p >= 0.8) return Colors.green.shade700;
    if (p >= 0.5) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final top = analysis.results.first;
    final isClear = top.key == 'Normal' ||
        top.key == 'No fracture' ||
        top.key == 'Healthy' ||
        top.key == 'Healthy teeth';
    final title = switch (widget.mode) {
      ScanMode.bone => 'Bone X-Ray Result',
      ScanMode.knee => 'Knee X-Ray Result',
      ScanMode.dental => 'Dental X-Ray Result',
      _ => 'Chest X-Ray Result',
    };
    final note = switch (widget.mode) {
      ScanMode.bone =>
        'Result by the Bone X-ray model — fracture screening only '
            '(No fracture / Fracture). It does not check for other '
            'bone problems.',
      ScanMode.knee =>
        'Result by the Knee X-ray model — osteoarthritis screening '
            'only (Healthy / Mild osteoarthritis / Severe '
            'osteoarthritis).',
      ScanMode.dental =>
        'Result by the Dental X-ray model — this is the check of '
            'the ONE tooth you selected (Healthy teeth / Cavity / '
            'Impacted tooth). Repeat the scan to check other teeth.',
      _ =>
        'Result by the Chest X-ray model — pneumonia screening '
            'only (Normal / Pneumonia). It does not check for other '
            'chest conditions.',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: Image.file(widget.image, height: 210, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            if (analysis.isUncertain)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.amberBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.amberBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline,
                        size: 20, color: AppTheme.amberText),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Low confidence — this result is uncertain. The '
                        'X-ray photo may be tilted, blurred or poorly '
                        'lit. Retake it straight and treat this result '
                        'with caution.',
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppTheme.amberText,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            if (analysis.isUncertain) const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prediction',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isClear)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.check_circle_outline,
                                size: 28, color: Color(0xFF2E7D32)),
                          ),
                        Text(top.key,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(top.value * 100).toStringAsFixed(1)}% confidence',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: _confidenceColor(top.value)),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: top.value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8EBF0),
                        color: _confidenceColor(top.value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Model scores',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            const SizedBox(height: 10),
            ...analysis.results.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(e.key,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink)),
                            ),
                            Text(
                              '${(e.value * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: e.value,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE8EBF0),
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 18, color: AppTheme.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20, color: AppTheme.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DRAFT — AI-assisted screening only, not a diagnosis. '
                      'Please consult a doctor.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportScreen(
                      image: widget.image,
                      results: analysis.results,
                      lowConfidence: analysis.isUncertain,
                      mode: widget.mode),
                ),
              ),
              icon: const Icon(Icons.description_outlined,
                  color: AppTheme.primary),
              label: const Text('Generate Report',
                  style: TextStyle(color: AppTheme.primary)),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_saved || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
              label: Text(_saved ? 'Saved to History' : 'Save to History'),
            ),
          ],
        ),
      ),
    );
  }
}
