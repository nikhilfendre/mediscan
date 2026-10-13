import 'dart:io';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';
import 'report_screen.dart';

/// Unified result screen: ONE photo, ONE answer.
///
/// Both models check the photo, but only one result is shown. The
/// winner is decided by the scan screen (see ScanScreen): the
/// clinical (camera-photo) model is the default authority, and the
/// lesion (dermoscopic) model overrules only on a near-certain
/// dermoscopic reading. Cases where neither model can read the
/// photo never reach this screen — the app abstains instead.
class ResultScreen extends StatefulWidget {
  final File image;

  /// 32-condition common-problems result (null if its gate failed).
  final SkinAnalysis? clinical;

  /// 7-condition lesion result (null if its gate failed).
  final SkinAnalysis? dermoscopy;

  /// Which model's result to present (decided by the scan screen).
  final ScanMode winner;

  const ResultScreen({
    super.key,
    required this.image,
    this.clinical,
    this.dermoscopy,
    required this.winner,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;
  bool _saving = false;

  /// The winning analysis and the model it came from.
  late final MapEntry<ScanMode, SkinAnalysis> _winner = MapEntry(
    widget.winner,
    widget.winner == ScanMode.clinical
        ? widget.clinical!
        : widget.dermoscopy!,
  );

  ScanMode get _mode => _winner.key;
  SkinAnalysis get _analysis => _winner.value;

  /// The model that did not decide (for the transparency note).
  ScanMode? get _otherMode {
    if (widget.clinical == null || widget.dermoscopy == null) return null;
    return _mode == ScanMode.clinical
        ? ScanMode.dermoscopy
        : ScanMode.clinical;
  }

  String _modelName(ScanMode m) => m == ScanMode.clinical
      ? 'Common Skin Problems model (32 conditions)'
      : 'Skin Lesion Check model (7 conditions)';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final store = FirestoreService();
      final url = await store.uploadScanImage(widget.image, scanId);
      final localPath =
          await store.saveScanImageLocally(widget.image, scanId);
      final a = _analysis;
      final top = a.results.first;
      await store.saveScan(
        label: top.key,
        confidence: top.value,
        top3: a.results.take(3).toList(),
        imageUrl: url,
        localImagePath: localPath,
        modelType: _mode.storageKey,
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
    final analysis = _analysis;
    final top = analysis.results.first;
    final top3 = analysis.results.take(3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
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
                        'photo may not show the problem clearly. Retake a '
                        'close-up, well-lit photo and treat this result '
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
            // Prediction card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prediction',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                    const SizedBox(height: 4),
                    Text(top.key,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink)),
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
            const Text('Top 3 possibilities',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            const SizedBox(height: 10),
            ...top3.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
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
                            color: i == 0
                                ? _confidenceColor(e.value)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            // Which model decided — small transparency note.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 18, color: AppTheme.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otherMode == null
                        ? 'Decided by the ${_modelName(_mode)}.'
                        : 'Both AI models checked this photo. This result '
                            'is from the ${_modelName(_mode)}.',
                    style:
                        const TextStyle(fontSize: 12.5, color: AppTheme.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // DRAFT disclaimer banner
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
                      'Please consult a dermatologist.',
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
                      mode: _mode),
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
