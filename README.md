# MediScan — AI-Assisted Medical Screening App

A Flutter mobile app that brings several AI screening tools together in
one place: skin problems, chest / bone / knee / dental X-rays and printed
lab reports. MediScan is an **AI-assisted decision-support tool** — it
helps a user understand what a photo or report may indicate and whether
a doctor visit is advisable. It is **not** a diagnostic device and never
prescribes medicine.

## Features

| Module | What it checks | Classes |
| --- | --- | --- |
| Skin Scan | Common skin problems + skin lesions (two AI models, one combined answer) | 32 + 7 |
| Chest X-Ray | Pneumonia screening | Normal / Pneumonia |
| Bone X-Ray | Fracture screening | No fracture / Fracture |
| Knee X-Ray | Osteoarthritis staging | Healthy / Mild / Severe |
| Dental X-Ray | Per-tooth check on a panoramic X-ray (crop one tooth) | Healthy / Cavity (caries) / Impacted |
| Lab Report Scan | Reads a printed blood report with on-device OCR and flags values outside their reference range | 24 tests |

- Every scan produces a readable **screening report** in the app, with a
  downloadable / shareable **A4 PDF**.
- Safety behaviour: non-medical or unclear photos are rejected instead of
  being forced into a disease class, and low-confidence results are
  clearly marked.
- Login (email + Google), personal scan **history** with photos, and
  cloud sync via Firebase.

## Model performance (held-out test sets)

| Model | Test accuracy | Test macro-F1 | Notes |
| --- | --- | --- | --- |
| Skin — common problems (32-class) | 0.718 | 0.709 | Fitzpatrick17k + SD-198 + DermNet |
| Skin — lesions (7-class, HAM10000) | — | 0.713 (val) | Dermoscopic images |
| Chest X-ray | 0.880 | 0.865 | Pneumonia sensitivity 0.974 |
| Bone fracture | 0.861 | 0.783 | FracAtlas dataset |
| Knee osteoarthritis | 0.733 | 0.755 | 3-stage (KL grade groups) |
| Dental (per-tooth) | 0.749 | 0.757 | DENTEX dataset; impacted-tooth recall 1.00 |

All models are EfficientNet-B0 based, trained/fine-tuned in PyTorch and
converted to TensorFlow Lite for fully on-device inference. Figures are
screening metrics on research datasets, not clinical validation.

## Tech stack

- **App:** Flutter (Dart), TensorFlow Lite, Google ML Kit (on-device OCR)
- **Backend:** Firebase Authentication + Cloud Firestore
- **Models:** PyTorch / EfficientNet-B0, converted with LiteRT
- **Reports:** in-app report + generated PDF

## Run it

```bash
flutter pub get
flutter run            # with a phone connected, or -d <device-id>
```

A Firebase Android config file (`android/app/google-services.json`) is
required for login/history features.

## Project

Final-year project, Department of Computer Engineering,
Yashwantrao Bhonsale Institute of Technology (YBIT), Sawantwadi.

**Team:** Nikhil P. Fendre, Harshad A. Naik, Utkarsh V. Parulekar,
Atharv O. Satardekar
**Guide:** Mrs. T. A. Walandkar

## Disclaimer

MediScan provides AI-assisted information only and is not a substitute
for professional medical diagnosis. Always consult a licensed healthcare
provider.
