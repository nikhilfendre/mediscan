import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'disease_info.dart';

/// Builds the MediScan screening report: on-screen content + a professional
/// A4 PDF. Wording is deliberately conservative — this is AI-assisted
/// screening support, never a diagnosis, and it never recommends medication.
class ReportService {
  /// Classes where a prompt in-person review is advised.
  static const _priorityLabels = {
    'Melanoma',
    'Basal cell carcinoma',
    'Squamous cell carcinoma',
    'Actinic keratosis',
    'Pneumonia',
    'Fracture',
  };

  static bool isPriority(String label) => _priorityLabels.contains(label);

  static String assessmentFor(String label, double confidence) {
    final pct = (confidence * 100).toStringAsFixed(1);
    if (label == 'Pneumonia') {
      return 'The AI model indicates signs that may be consistent with '
          'pneumonia in this chest X-ray, with $pct% confidence. This '
          'screening result alone does not confirm pneumonia; a doctor '
          'must correlate it with symptoms, examination and, if needed, '
          'further tests. Please seek medical care promptly.';
    }
    if (label == 'Normal') {
      return 'The AI model did not find signs of pneumonia in this '
          'chest X-ray (Normal, $pct% confidence). A normal screening '
          'result does not rule out all chest conditions. If symptoms '
          'such as fever, cough or breathlessness persist, please see '
          'a doctor.';
    }
    if (label == 'Fracture') {
      return 'The AI model indicates signs that may be consistent '
          'with a fracture in this bone X-ray, with $pct% confidence. '
          'This screening result alone does not confirm a fracture; '
          'an orthopaedic doctor must examine the X-ray and the '
          'injured part. Please seek medical care promptly and keep '
          'the injured part still and supported.';
    }
    if (label == 'No fracture') {
      return 'The AI model did not find signs of a fracture in this '
          'bone X-ray (No fracture, $pct% confidence). A normal '
          'screening result does not rule out a fine hairline '
          'fracture or soft-tissue injury. If pain or swelling '
          'persists or worsens, please see a doctor.';
    }
    if (label == 'Severe osteoarthritis') {
      return 'The AI model indicates signs of severe '
          'osteoarthritis in this knee X-ray, with $pct% confidence. '
          'This is a screening estimate of joint wear, not a final '
          'grading; an orthopaedic doctor should review the X-ray '
          'along with your symptoms and plan treatment.';
    }
    if (label == 'Mild osteoarthritis') {
      return 'The AI model indicates signs of mild osteoarthritis '
          'in this knee X-ray, with $pct% confidence. Early '
          'wear-and-tear changes like these are common and usually '
          'managed with exercise, weight control and follow-up; a '
          'doctor can confirm the finding on examination.';
    }
    if (label == 'Healthy') {
      return 'The AI model found no signs of osteoarthritis in '
          'this knee X-ray (Healthy, $pct% confidence). Knee pain '
          'can also arise from muscles, ligaments or the kneecap, '
          'which an X-ray does not show well. If pain persists, '
          'please see a doctor.';
    }
    if (label == 'Cavity (caries)') {
      return 'The AI model indicates signs of tooth decay '
          '(a cavity) in one part of this dental X-ray, with $pct% '
          'confidence. Cavities found early are simpler to treat. '
          'A dentist can confirm the finding on examination. This '
          'screening result alone does not confirm the finding.';
    }
    if (label == 'Impacted tooth') {
      return 'The AI model indicates a tooth that appears stuck '
          'or not fully erupted (impacted) in one part of this '
          'dental X-ray, with $pct% confidence - commonly a wisdom '
          'tooth. A dentist should review the X-ray and advise '
          'whether it needs monitoring or removal.';
    }
    if (label == 'Healthy teeth') {
      return 'The AI model found no cavity, deep decay or '
          'impacted tooth in the main part of this dental X-ray '
          '(Healthy teeth, $pct% confidence). This is a screening '
          'result only; small problems between teeth can be '
          'missed on a screening scan. If you have tooth pain, '
          'sensitivity or swelling, please see a dentist.';
    }
    if (isPriority(label)) {
      return 'The AI model indicates a possibility of $label with $pct% '
          'confidence. Findings in this category should be reviewed promptly '
          'by a dermatologist, including dermoscopic examination and, if '
          'required, biopsy. This screening result alone does not confirm '
          'any condition.';
    }
    return 'The AI model indicates a possibility of $label with $pct% '
        'confidence. This screening result alone does not confirm any '
        'condition; only an in-person dermatologist examination can do '
        'that. If the problem persists, spreads or worsens, please get '
        'it examined.';
  }

  static List<String> nextStepsFor(String label) {
    if (label == 'Pneumonia') {
      return [
        'Consult a doctor at the earliest opportunity.',
        'Carry this report and the original X-ray to the appointment.',
        'Note your symptoms (fever, cough, breathing difficulty) and inform the doctor.',
        'Avoid self-medication, including antibiotics, without a prescription.',
      ];
    }
    if (label == 'Normal') {
      return [
        'No action is usually needed if you have no symptoms.',
        'See a doctor if fever, cough, chest pain or breathlessness persists or worsens.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Fracture') {
      return [
        'Consult an orthopaedic doctor at the earliest opportunity.',
        'Keep the injured part still, supported and raised if possible.',
        'Carry this report and the original X-ray to the appointment.',
        'Avoid self-treatment, massage or home remedies on the injured part.',
      ];
    }
    if (label == 'No fracture') {
      return [
        'Rest the injured part and avoid heavy use for a few days.',
        'See a doctor if pain or swelling does not improve in 3-4 days, or worsens.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Severe osteoarthritis') {
      return [
        'Consult an orthopaedic doctor for a treatment plan.',
        'Stay active within comfort; ask about physiotherapy and muscle strengthening.',
        'Carry this report and the original X-ray to the appointment.',
        'Avoid self-medication for long periods without medical advice.',
      ];
    }
    if (label == 'Mild osteoarthritis') {
      return [
        'Stay active with low-impact exercise (walking, cycling, swimming).',
        'Work on thigh-muscle strengthening and healthy weight.',
        'See a doctor if pain or swelling keeps recurring.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Healthy') {
      return [
        'No action is usually needed if you have no symptoms.',
        'See a doctor if knee pain persists beyond a few weeks or the knee locks or gives way.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Cavity (caries)') {
      return [
        'Book a dental check-up - early cavities are simpler and cheaper to treat.',
        'Brush twice daily with fluoride toothpaste and cut down on sugary snacks and drinks.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Impacted tooth') {
      return [
        'Show the X-ray to a dentist - impacted teeth (often wisdom teeth) need a review.',
        'Mention any pain, swelling or repeated infection near that tooth.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (label == 'Healthy teeth') {
      return [
        'No action is usually needed if you have no symptoms.',
        'Continue regular dental check-ups every 6-12 months.',
        'See a dentist if you have tooth pain, sensitivity or swelling, even with a healthy screening result.',
        'Keep this report and the original X-ray for your records.',
      ];
    }
    if (isPriority(label)) {
      return [
        'Consult a dermatologist at the earliest opportunity.',
        'Carry this report and the original photo to the appointment.',
        'Avoid self-medication or home remedies on the lesion.',
        'Note any recent change (growth, colour, itching, bleeding) and inform the doctor.',
      ];
    }
    return [
      'Monitor the affected area and re-scan if it changes.',
      'Consult a dermatologist if it spreads, worsens, or does not improve.',
      'Carry this report and the original photo to any skin appointment.',
      'Avoid self-medication or home remedies on the affected area.',
    ];
  }

  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  /// Renders the report as a print-ready A4 PDF document.
  static Future<Uint8List> buildPdf({
    required File? image,
    required List<MapEntry<String, double>> results,
    required String patientName,
    required String patientEmail,
    required String reportId,
    required DateTime generatedAt,
    bool lowConfidence = false,
    String modelLabel = 'Skin lesion model - 7 conditions (dermoscopic images)',
    String reportTitle = 'AI-Assisted Skin Screening Report',
  }) async {
    final top = results.first;
    final navy = PdfColor.fromHex('#0D2B4E');
    final teal = PdfColor.fromHex('#009688');
    final grey = PdfColor.fromHex('#5A6577');
    final lightGrey = PdfColor.fromHex('#EEF1F6');
    final amberBg = PdfColor.fromHex('#FFF4D6');
    final amberText = PdfColor.fromHex('#7A5200');

    pw.MemoryImage? photo;
    if (image != null) {
      try {
        photo = pw.MemoryImage(await image.readAsBytes());
      } catch (_) {
        photo = null;
      }
    }

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 130,
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

    pw.Widget section(String title) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 12.5,
                  fontWeight: pw.FontWeight.bold,
                  color: navy)),
        );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Letterhead
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MediScan',
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white)),
                        pw.Text(reportTitle,
                            style: pw.TextStyle(
                                fontSize: 10.5, color: PdfColors.white)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber200,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text('DRAFT',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: amberText)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            kv('Report ID', reportId),
            kv('Generated on', formatDate(generatedAt)),
            kv('Patient', patientName),
            kv('Email', patientEmail),
            kv('Analysis model', modelLabel),
            pw.Divider(color: lightGrey, thickness: 1.2),
            section('Scan Image'),
            if (photo != null)
              pw.Container(
                height: 170,
                width: 240,
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(photo, fit: pw.BoxFit.cover),
                ),
              )
            else
              pw.Text('Image unavailable',
                  style: pw.TextStyle(fontSize: 10.5, color: grey)),
            section('Findings'),
            kv('Prediction', top.key),
            kv('Confidence', '${(top.value * 100).toStringAsFixed(1)}%'),
            kv('Review priority',
                isPriority(top.key) ? 'Priority - prompt review advised' : 'Routine'),
            if (lowConfidence)
              kv('Note',
                  'Low-confidence result - interpret with caution and prefer an in-person medical review.'),
            section('Differential Diagnosis (Top 3)'),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGrey, width: 1.2),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    color: lightGrey,
                    child: pw.Row(children: [
                      pw.Expanded(
                          child: pw.Text('Condition',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Text('Probability',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                    ]),
                  ),
                  ...results.take(3).map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: pw.Row(children: [
                            pw.Expanded(
                                child: pw.Text(e.key,
                                    style:
                                        const pw.TextStyle(fontSize: 10.5))),
                            pw.Text(
                                '${(e.value * 100).toStringAsFixed(1)}%',
                                style: const pw.TextStyle(fontSize: 10.5)),
                          ]),
                        ),
                      ),
                ],
              ),
            ),
            section('About This Condition'),
            pw.Text('What it is',
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(DiseaseInfo.forLabel(top.key).about,
                style:
                    pw.TextStyle(fontSize: 10.5, color: grey, lineSpacing: 3)),
            pw.SizedBox(height: 5),
            pw.Text('Why it happens',
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(DiseaseInfo.forLabel(top.key).causes,
                style:
                    pw.TextStyle(fontSize: 10.5, color: grey, lineSpacing: 3)),
            pw.SizedBox(height: 5),
            pw.Text('What you should do',
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            ...DiseaseInfo.forLabel(top.key).care.map(
              (c) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('-  $c',
                    style: pw.TextStyle(
                        fontSize: 10.5, color: grey, lineSpacing: 3)),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Treatment overview',
                style: pw.TextStyle(
                    fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(DiseaseInfo.forLabel(top.key).treatment,
                style:
                    pw.TextStyle(fontSize: 10.5, color: grey, lineSpacing: 3)),
            pw.SizedBox(height: 4),
            pw.Text(
                'General information only - not a prescription. Any medicine or procedure is decided by a dermatologist after examination.',
                style: pw.TextStyle(
                    fontSize: 9,
                    color: grey,
                    fontStyle: pw.FontStyle.italic)),
            section('Assessment'),
            pw.Text(assessmentFor(top.key, top.value),
                style:
                    pw.TextStyle(fontSize: 10.5, color: grey, lineSpacing: 3)),
            section('Recommended Next Steps'),
            ...nextStepsFor(top.key).map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('-  ',
                        style: pw.TextStyle(fontSize: 10.5, color: teal)),
                    pw.Expanded(
                        child: pw.Text(s,
                            style: pw.TextStyle(
                                fontSize: 10.5, color: grey, lineSpacing: 3))),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: amberBg,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Disclaimer: This report is generated by an AI screening '
                'system (MediScan) for decision support only. It is not a '
                'medical diagnosis and does not replace examination by a '
                'qualified medical professional.',
                style: pw.TextStyle(
                    fontSize: 9, color: amberText, lineSpacing: 2.5),
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: lightGrey, thickness: 1.2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by MediScan - AI-assisted screening',
                    style: pw.TextStyle(fontSize: 8.5, color: grey)),
                pw.Text('Page 1 of 1',
                    style: pw.TextStyle(fontSize: 8.5, color: grey)),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
