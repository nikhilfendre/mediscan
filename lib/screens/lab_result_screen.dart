import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/firestore_service.dart';
import '../services/lab_report_pdf.dart';
import '../services/lab_report_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

/// Shows the values read from one lab report with Low / Normal /
/// High flags. Used right after a scan (with Save) and from
/// History (read-only, [fromHistory]).
class LabResultScreen extends StatefulWidget {
  final File? image;
  final String? imageUrl;
  final String? localImagePath;
  final List<LabTestResult> results;
  final DateTime? scannedAt;
  final bool fromHistory;

  const LabResultScreen({
    super.key,
    required this.results,
    this.image,
    this.imageUrl,
    this.localImagePath,
    this.scannedAt,
    this.fromHistory = false,
  });

  @override
  State<LabResultScreen> createState() => _LabResultScreenState();
}

class _LabResultScreenState extends State<LabResultScreen> {
  bool _saving = false;
  bool _saved = false;

  int get _abnormal => widget.results.where((r) => !r.isNormal).length;

  String get _summaryLabel {
    final n = widget.results.length;
    if (_abnormal == 0) return 'Lab Report: All $n values in range';
    return 'Lab Report: $_abnormal of $n values out of range';
  }

  File? get _pdfImage {
    if (widget.image != null) return widget.image;
    if (widget.localImagePath != null) return File(widget.localImagePath!);
    return null;
  }

  Future<void> _save() async {
    if (widget.image == null) return;
    setState(() => _saving = true);
    try {
      final scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final store = FirestoreService();
      final url = await store.uploadScanImage(widget.image!, scanId);
      final localPath =
          await store.saveScanImageLocally(widget.image!, scanId);
      await store.saveScan(
        label: _summaryLabel,
        confidence: 0,
        top3: const [],
        imageUrl: url,
        localImagePath: localPath,
        modelType: 'lab',
        extra: {
          'labRows': widget.results.map((r) => r.toMap()).toList(),
        },
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

  Future<void> _pdf(bool share) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ??
        (user?.email != null ? user!.email!.split('@').first : 'Patient');
    final bytes = await LabReportPdf.build(
      image: _pdfImage,
      results: widget.results,
      patientName: name,
      patientEmail: user?.email ?? '',
      reportId: 'MS-${(widget.scannedAt ?? DateTime.now()).millisecondsSinceEpoch}',
      generatedAt: widget.scannedAt ?? DateTime.now(),
    );
    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: 'mediscan-lab-report.pdf');
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  Widget _photo() {
    if (widget.image != null) {
      return Image.file(widget.image!, fit: BoxFit.cover);
    }
    if (widget.localImagePath != null &&
        File(widget.localImagePath!).existsSync()) {
      return Image.file(File(widget.localImagePath!), fit: BoxFit.cover);
    }
    if (widget.imageUrl != null) {
      return Image.network(widget.imageUrl!, fit: BoxFit.cover);
    }
    return const Center(
        child: Icon(Icons.description_outlined,
            size: 48, color: AppTheme.muted));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.results.length;
    final ok = _abnormal == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Report Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photo(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ok
                    ? AppTheme.accent.withOpacity(0.10)
                    : const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(
                    color: ok ? AppTheme.accent : const Color(0xFFE3B505),
                    width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: ok ? AppTheme.accent : const Color(0xFF9A7300),
                      size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ok
                          ? 'All $total values are within their reference range.'
                          : '$_abnormal of $total values are outside their reference range.',
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...widget.results.map(_rowCard),
            const SizedBox(height: 6),
            const Text(
              'Ranges shown are the ones printed on your report where '
              'they could be read; otherwise standard adult reference '
              'ranges are used. Ranges differ between labs, and a '
              'value outside the range is not by itself a diagnosis. '
              'Please confirm with the original report and discuss '
              'with your doctor.',
              style:
                  TextStyle(fontSize: 12.5, height: 1.45, color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            if (!widget.fromHistory)
              ElevatedButton.icon(
                onPressed: (_saving || _saved) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
                label: Text(_saved ? 'Saved' : 'Save to History'),
              ),
            if (!widget.fromHistory) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pdf(false),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('PDF Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pdf(true),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            if (widget.scannedAt != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Scanned on ${ReportService.formatDate(widget.scannedAt!)}',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowCard(LabTestResult r) {
    final chipColor = r.isNormal ? AppTheme.accent : const Color(0xFFC62828);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border(
          left: BorderSide(
              color: r.isNormal ? AppTheme.accent : const Color(0xFFC62828),
              width: 4),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text(
                  'Range: ${r.rangeText}${r.rangeFromReport ? '' : ' (standard)'}',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.valueText} ${r.unit}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(r.status,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: chipColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
