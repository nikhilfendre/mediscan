import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/disease_info.dart';
import '../services/report_service.dart';
import '../services/skin_model_service.dart';
import '../theme/app_theme.dart';

/// On-screen screening report for one scan, with PDF download / share.
/// Mirrors the Streamlit AI Report Draft: case details, prediction,
/// top-3 differential, assessment, next steps and the DRAFT disclaimer.
class ReportScreen extends StatefulWidget {
  /// Local scan photo (fresh scan) — null when opened from History.
  final File? image;

  /// Remote scan photo URL from Firestore — used when [image] is null.
  final String? imageUrl;

  /// On-device copy of the scan photo (app documents folder) — used
  /// when [image] is null and no remote URL exists.
  final String? localImagePath;

  final List<MapEntry<String, double>> results;

  /// Original scan time when opened from History; defaults to now.
  final DateTime? scannedAt;

  /// Flags weak predictions in the report and its PDF.
  final bool lowConfidence;

  /// Which model produced this scan (named in the report).
  final ScanMode mode;

  const ReportScreen({
    super.key,
    this.image,
    this.imageUrl,
    this.localImagePath,
    required this.results,
    this.scannedAt,
    this.lowConfidence = false,
    this.mode = ScanMode.dermoscopy,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final String _reportId;
  late final DateTime _generatedAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _generatedAt = widget.scannedAt ?? DateTime.now();
    _reportId = 'MS-${_generatedAt.millisecondsSinceEpoch}';
  }

  String get _patientName {
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email?.split('@').first ?? 'MediScan User';
  }

  String get _patientEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  /// The locally saved scan photo, if it still exists on this phone.
  File? get _savedFile {
    final p = widget.localImagePath;
    if (p == null) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  Future<void> _withPdf(Future<void> Function(Uint8List bytes) action) async {
    setState(() => _busy = true);
    try {
      final bytes = await ReportService.buildPdf(
        image: widget.image ?? _savedFile,
        results: widget.results,
        patientName: _patientName,
        patientEmail: _patientEmail,
        reportId: _reportId,
        generatedAt: _generatedAt,
        lowConfidence: widget.lowConfidence,
        modelLabel: widget.mode.reportLabel,
        reportTitle: switch (widget.mode) {
          ScanMode.xray => 'AI-Assisted Chest X-Ray Screening Report',
          ScanMode.bone => 'AI-Assisted Bone X-Ray Screening Report',
          ScanMode.knee => 'AI-Assisted Knee X-Ray Screening Report',
          ScanMode.dental => 'AI-Assisted Dental X-Ray Screening Report',
          _ => 'AI-Assisted Skin Screening Report',
        },
      );
      await action(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() => _withPdf(
        (bytes) => Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'MediScan_Report_$_reportId',
        ),
      );

  Future<void> _share() => _withPdf(
        (bytes) => Printing.sharePdf(
            bytes: bytes, filename: 'MediScan_Report_$_reportId.pdf'),
      );

  Widget _row(String label, String value, {bool bold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13.5, color: AppTheme.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
      );

  Widget _subHead(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 3),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink)),
      );

  Widget _body(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13.5, height: 1.5, color: AppTheme.muted));

  @override
  Widget build(BuildContext context) {
    final top = widget.results.first;
    final top3 = widget.results.take(3).toList();
    final info = DiseaseInfo.forLabel(top.key);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report document card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety,
                            size: 22, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('MediScan — Screening Report',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.amberBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('DRAFT',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.amberText)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    _row('Patient', _patientName),
                    _row('Email', _patientEmail, bold: false),
                    _row('Report ID', _reportId),
                    _row('Date', ReportService.formatDate(_generatedAt)),
                    _row('Analysis model', widget.mode.reportLabel,
                        bold: false),
                    const SizedBox(height: 8),
                    if (widget.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(widget.image!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      )
                    else if (_savedFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_savedFile!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      )
                    else if (widget.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.imageUrl!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    _sectionTitle('Findings'),
                    _row('Prediction', top.key),
                    _row('Confidence',
                        '${(top.value * 100).toStringAsFixed(1)}%'),
                    _row(
                      'Review priority',
                      ReportService.isPriority(top.key)
                          ? 'Priority — prompt review advised'
                          : 'Routine',
                    ),
                    if (widget.lowConfidence)
                      _row('Note',
                          'Low-confidence result — interpret with caution'),
                    _sectionTitle('Differential (Top 3)'),
                    ...top3.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '•  ${e.key} — ${(e.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 13.5, color: AppTheme.ink),
                        ),
                      ),
                    ),
                    _sectionTitle('About This Condition'),
                    _subHead('What it is'),
                    _body(info.about),
                    _subHead('Why it happens'),
                    _body(info.causes),
                    _subHead('What you should do'),
                    ...info.care.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(
                                    fontSize: 13.5, color: AppTheme.accent)),
                            Expanded(child: _body(c)),
                          ],
                        ),
                      ),
                    ),
                    _subHead('Treatment overview'),
                    _body(info.treatment),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.mode == ScanMode.dermoscopy ||
                                widget.mode == ScanMode.clinical
                            ? 'General information only - not a '
                                'prescription. Any medicine or procedure '
                                'is decided by a dermatologist after '
                                'examination.'
                            : 'General information only - not a '
                                'prescription. Any medicine or procedure '
                                'is decided by a doctor after examination.',
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.muted),
                      ),
                    ),
                    _sectionTitle('Assessment'),
                    Text(
                      ReportService.assessmentFor(top.key, top.value),
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppTheme.muted),
                    ),
                    _sectionTitle('Recommended Next Steps'),
                    ...ReportService.nextStepsFor(top.key).map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ',
                                style: TextStyle(
                                    fontSize: 13.5, color: AppTheme.accent)),
                            Expanded(
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      color: AppTheme.muted)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const DisclaimerStrip(
                      text:
                          'This report is AI-generated for screening support only and is not a medical diagnosis.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download_outlined),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.share_outlined,
                        color: AppTheme.primary),
                    label: const Text('Share',
                        style: TextStyle(color: AppTheme.primary)),
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 52)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
