import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'lab_report_service.dart';

/// A4 PDF for a lab report check - same visual identity as the
/// screening reports (navy header, clean table). ASCII text only,
/// like the rest of the app's PDFs.
class LabReportPdf {
  static Future<Uint8List> build({
    required File? image,
    required List<LabTestResult> results,
    required String patientName,
    required String patientEmail,
    required String reportId,
    required DateTime generatedAt,
  }) async {
    final navy = PdfColor.fromHex('#0D2B4E');
    final teal = PdfColor.fromHex('#009688');
    final grey = PdfColor.fromHex('#5A6577');
    final lightGrey = PdfColor.fromHex('#EEF1F6');
    final red = PdfColor.fromHex('#C62828');

    pw.MemoryImage? photo;
    if (image != null) {
      try {
        photo = pw.MemoryImage(await image.readAsBytes());
      } catch (_) {
        photo = null;
      }
    }

    final abnormal = results.where((r) => !r.isNormal).length;
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(generatedAt);

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(k,
                    style: pw.TextStyle(fontSize: 10.5, color: grey)),
              ),
              pw.Expanded(
                child: pw.Text(v,
                    style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1A2433'))),
              ),
            ],
          ),
        );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MediScan',
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.Text('AI-Assisted Lab Report Check',
                        style: pw.TextStyle(
                            fontSize: 11, color: PdfColors.white)),
                  ],
                ),
                pw.Text('Report',
                    style: pw.TextStyle(
                        fontSize: 12, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          kv('Report ID', reportId),
          kv('Patient', patientName),
          if (patientEmail.isNotEmpty) kv('Email', patientEmail),
          kv('Generated', dateStr),
          kv('Summary',
              '${results.length} values read, $abnormal outside the reference range'),
          pw.SizedBox(height: 10),
          if (photo != null) ...[
            pw.Container(
              height: 200,
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Text('Values read from the report',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: navy)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: lightGrey, width: 0.7),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.2),
              1: const pw.FlexColumnWidth(1.7),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: navy),
                children: [
                  for (final h in ['Test', 'Value', 'Reference range', 'Status'])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                ],
              ),
              for (final r in results)
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: r.isNormal ? PdfColors.white : PdfColor.fromHex('#FDECEA')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(r.name,
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${r.valueText} ${r.unit}',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                          '${r.rangeText}${r.rangeFromReport ? '' : ' (standard)'}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(r.status,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: r.isNormal ? teal : red)),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Note: values were read automatically from a photo of the '
            'report and can contain reading errors - always confirm '
            'with the original lab report. Reference ranges differ '
            'between labs; ranges printed on the report were used '
            'where readable, otherwise standard adult ranges. A value '
            'outside its range is not by itself a diagnosis. This '
            'tool provides information only and does not replace '
            'professional medical advice.',
            style: pw.TextStyle(fontSize: 9.5, color: grey),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
