# 🌿 Plant Disease Detection App

> An offline-first, AI-powered mobile and desktop application for detecting plant diseases using on-device TensorFlow Lite models. Built with Flutter as a final Master's thesis project.

---

## Overview

This application enables farmers, agronomists, and researchers to diagnose plant diseases by photographing crop leaves directly from a smartphone or desktop. A five-stage offline inference pipeline validates the image, runs a TFLite model, and delivers a structured diagnostic report — all without an internet connection.

The system currently supports **tomato**, **potato**, and a general multi-crop model, covering diseases including bacterial spot, early blight, late blight, leaf mold, septoria leaf spot, and more.

---

## Features

- **On-device AI inference** — TensorFlow Lite models run entirely on the device; no data is sent to a server
- **Multi-architecture model support** — handles both EfficientNet-style classification models `[1, num_classes]` and YOLOv12-style detection models `[1, 4+classes, anchors]`
- **Five-stage inference pipeline**
  1. Image decode
  2. Plant presence validation (colour, sharpness, brightness)
  3. TFLite inference
  4. Entropy-based confidence penalty
  5. Confidence-tier human-readable response
- **Structured diagnostic reports** with observed symptoms, biological explanation, severity level, organic treatments, chemical treatments, environmental corrections, and prevention steps
- **Scan history** with GPS coordinates stored in a local SQLite database
- **Interactive disease map** powered by OpenStreetMap (flutter_map), showing geotagged detections
- **Disease library** — searchable offline reference covering 15+ diseases
- **Cross-platform** — Android, iOS, macOS, Windows, Linux, and Web (inference disabled on web)
- **Offline-first** — full functionality without internet; map tiles degrade gracefully when offline
- **Glassmorphic dark UI** with animated navigation sheet, glowing indicators, and smooth transitions

---

## Supported Diseases

| Disease | Category | Crops |
|---|---|---|
| Bacterial Spot | Bacterial | Tomato, Pepper |
| Early Blight | Fungal | Tomato, Potato |
| Late Blight | Oomycete | Tomato, Potato |
| Leaf Mold | Fungal | Tomato |
| Powdery Mildew | Fungal | Many crops |
| Rust | Fungal | Many crops |
| Septoria Leaf Spot | Fungal | Tomato |
| Spider Mites | Pest | Many crops |
| Target Spot | Fungal | Tomato |
| Yellow Leaf Curl Virus | Viral | Tomato |
| Mosaic Virus | Viral | Many crops |
| Fusarium Wilt | Fungal | Tomato, Banana |
| Verticillium Wilt | Fungal | Tomato, Potato |
| Root Rot | Fungal/Oomycete | Most crops |
| Healthy | — | All |

---

## Architecture

```
lib/
├── main.dart                       # App entry point, SQLite FFI init
├── app_theme.dart                  # Design tokens, glassmorphic card widget
├── home_screen.dart                # Scan history list, FAB camera trigger
├── check_screen.dart               # Image capture, processing, report display
├── inference_pipeline.dart         # 5-stage pipeline (validate → infer → respond)
├── plant_validator.dart            # Image quality + organic colour detection
├── efficientnet_model_io.dart      # TFLite wrapper (classification + YOLO)
├── efficientnet_model_web.dart     # Web stub (inference not supported)
├── efficientnet_model.dart         # Conditional export (io vs web)
├── diagnostic_report_generator.dart # Assembles DiagnosticReport from InferenceResult
├── diagnostic_report.dart          # Report data model
├── disease_knowledge_base.dart     # Offline knowledge entries for all diseases
├── disease_data.dart               # Static reference data for LibraryScreen
├── disease_screen.dart             # Disease detail view
├── library_screen.dart             # Searchable disease library
├── maps_screen.dart                # flutter_map with geotagged detections
├── crops_screen.dart               # Model/crop selection
├── glass_nav_sheet.dart            # Animated glassmorphic navigation sheet
├── database_helper.dart            # SQLite CRUD (scan history)
├── connectivity_service.dart       # DNS-based online check
├── firebase_helper.dart            # Placeholder (Firebase disabled)
└── models.dart                     # Data models: History, Disease, Crop, Alert
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.38.0`
- Dart SDK `>=3.11.0`
- For **Linux/Windows desktop**: build the TFLite C library (see below)
- For **Android/iOS**: TFLite libraries are bundled automatically via `tflite_flutter`

### Install dependencies

```bash
flutter pub get
```

### Run on Android or iOS

```bash
flutter run
```

### Run on Linux desktop

The TFLite C shared library must be built before first run:

```bash
bash tools/setup_tflite.sh
flutter run -d linux
```

> `setup_tflite.sh` clones TensorFlow v2.14.0 (shallow), builds `libtensorflowlite_c.so` with CMake/Ninja, and installs it to `blobs/`. Takes 20–40 minutes on first run.

### Run on Windows desktop

```bash
flutter run -d windows
```

### Run on Web

```bash
flutter run -d chrome
```

> Disease inference is disabled on web — a friendly message is shown instead. All other features (history, library, maps) are available.

---

## Model Files

Place your TFLite model files under `assets/models/`:

| File | Used for |
|---|---|
| `best_float32_for_all_crops.tflite` | General multi-crop model |
| `best_float32_tomato.tflite` | Tomato-specific model |
| `best_float32_potato.tflite` | Potato-specific model |

Label files go under `assets/labels/`:

| File | Matches model |
|---|---|
| `all_crops_labels.txt` | General model |
| `tomato_labels.txt` | Tomato model |
| `potato_labels.txt` | Potato model |

The app reads the label file at runtime and maps model output indices to disease names. Both EfficientNet-style (classification) and YOLOv12-style (detection) model output shapes are handled automatically.

---

## Plant Validation Pipeline

Before calling the TFLite model, a three-stage image validator runs on a 128×128 thumbnail:

1. **Brightness check** — rejects images that are too dark (<15/255 mean) or overexposed (>250/255 mean)
2. **Sharpness check** — approximated Laplacian score; blurry images are rejected unless the organic colour score is strong enough to bypass this gate
3. **Organic colour detection** — counts pixels whose HSV hue and saturation fall in the palette of living or diseased plant tissue (greens, yellow-greens, yellow-browns, red-browns); requires ≥7% coverage

This prevents false diagnoses from photos of non-plant subjects, screens, or solid backgrounds.

---

## Confidence Tier System

The pipeline penalises confidence using normalised Shannon entropy of the model's output probability distribution — a near-uniform distribution means the model is uncertain regardless of the top-1 score.

| Effective confidence | Tier | Behaviour |
|---|---|---|
| ≥ 70% | High | Direct diagnosis shown, saved to history |
| 45–70% | Medium | Diagnosis shown with "moderate confidence" caveat |
| 22–45% | Low | Plant confirmed, condition unclear — user prompted to retake |
| < 22% | Uncertain | Cannot diagnose — user prompted to retake |

---

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `tflite_flutter` | ^0.12.1 | On-device TFLite inference |
| `image` | ^4.1.3 | Image decoding and preprocessing |
| `sqflite` | ^2.3.2 | Local SQLite scan history |
| `sqflite_common_ffi` | ^2.4.0 | Desktop SQLite support |
| `flutter_map` | ^7.0.2 | OpenStreetMap-based detection map |
| `latlong2` | ^0.9.1 | Geographic coordinate types |
| `geolocator` | ^11.0.0 | GPS location capture |
| `image_picker` | ^1.0.7 | Camera and gallery image selection |
| `shared_preferences` | ^2.2.2 | Crop reference preference storage |
| `path_provider` | ^2.1.3 | App documents directory |
| `provider` | ^6.1.2 | State management |

---

## Permissions

### Android
- `CAMERA` — photo capture
- `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES` — gallery import
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` — GPS tagging
- `INTERNET` — map tiles (optional; app works offline without it)

### iOS / macOS
- Camera and photo library usage descriptions required in `Info.plist`
- Location usage description required

---

## Project Structure (Non-Dart)

```
android/          Native Android runner
ios/              Native iOS runner
macos/            Native macOS runner
linux/            GTK-based Linux runner + CMake build
windows/          Win32-based Windows runner + CMake build
web/              Flutter web entry point
assets/
  models/         TFLite model files (not committed — add your own)
  labels/         Label text files
blobs/            Platform native libraries (libtensorflowlite_c-linux.so)
tools/
  setup_tflite.sh Linux TFLite C library build script
```

---

## Known Limitations

- TFLite inference is not available on the web build
- The Linux TFLite C library must be compiled from source (see `tools/setup_tflite.sh`)
- Firebase integration is disabled (placeholder in `firebase_helper.dart`)
- Map tiles require an internet connection; pins are still shown offline

---

## Academic Context

This project was developed as a **Master's thesis** in partial fulfilment of the requirements for a postgraduate degree. The research explores the feasibility of deploying convolutional neural network-based plant disease classification on resource-constrained mobile and desktop devices using an offline-first architecture.

The thesis covers the full development lifecycle: literature review, dataset preparation, model training (EfficientNet and YOLOv12 architectures), Flutter application design, evaluation of inference accuracy, and field usability assessment.

---

## License

This project was developed for academic purposes. All rights reserved by the author.
