# Camera & Animal Report Creation — Testing & Architecture Guide

Welcome to the **Camera & Animal Report Creation** testing guide for **Paws and Found**. This document explains how the camera subsystem operates, how live camera hardware and fallback mechanisms work, how spatial data and photos are processed, and how to verify and test the feature end-to-end.

---

## 1. Architectural Overview

The camera feature is located in [`lib/features/report/`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/report) and integrates with [`lib/shared/`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/shared) using **Clean Architecture** and **Atomic Design**.

### Directory Structure

```text
mobile_app/
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── location_service.dart          # GPS hardware & live position coordinator
│   │   ├── network/
│   │   │   └── orchestrator_client.dart       # HTTP client with Supabase JWT auth for AI service
│   │   └── routes/
│   │       └── app_router.dart                # Registered routes: /camera, /report, /home, /map
│   ├── shared/
│   │   ├── atoms/
│   │   │   └── camera_viewfinder_brackets.dart # Corner framing brackets overlay (┌ ┐ └ ┘)
│   │   ├── molecules/
│   │   │   ├── camera_viewfinder_placeholder.dart # Live camera stream, shutter button & gallery picker
│   │   │   └── camerafound_icon.dart          # Center camera icon in bottom navigation bar
│   │   └── organisms/
│   │       ├── create_report_form.dart        # Animal type, status, description, date, GPS & submit
│   │       └── custom_app_bar.dart            # Bottom navigation bar (Tab 2 active)
│   └── features/
│       ├── dashboard/
│       │   └── presentation/pages/dashboard_page.dart # App shell managing tab index & camera lifecycle
│       └── report/
│           ├── domain/
│           │   ├── entities/report.dart       # SightingReport entity (with analysisStatus)
│           │   └── repositories/report_repository.dart # Interface contract
│           ├── data/
│           │   ├── models/report_model.dart   # Model mapping to PostGIS reports schema
│           │   ├── datasources/report_remote_datasource.dart # Supabase Storage & PostGIS RPC
│           │   └── repositories/report_repository_impl.dart  # Data repository & AI dispatch hook
│           └── presentation/
│               ├── pages/camera_report_page.dart             # Live camera screen coordinator & lifecycle
│               └── providers/camera_report_controller.dart   # Presentation state controller
└── test/
    └── camera_widget_test.dart                 # Widget & integration test suite (5 passing tests)
```

---

## 2. How the Camera Subsystem Works

### A. Real-Time In-App Camera Viewfinder
* Uses Flutter's official **[`camera`](https://pub.dev/packages/camera)** plugin (`^0.12.1`).
* On initialization, searches available device cameras and selects the **rear-facing camera** by default (ideal for photographing animals).
* Live frames are rendered via `CameraPreview` inside the viewfinder container, scaled using `FittedBox(fit: BoxFit.cover)` to eliminate black borders.
* Corner framing brackets (`CameraViewfinderBrackets`) are rendered over the live stream with `IgnorePointer` so they do not block tap gestures.
* Tapping the center **circular shutter button** calls `CameraController.takePicture()`, captures the still, reads image bytes, and switches to the preview view.

### B. Hardware Lifecycle & Battery Optimization
* The camera is only active when Tab 2 is visible (`isActiveTab == true`).
* When switching to other tabs (Map, Feed, Notifications, Profile), the camera preview pauses to conserve device battery and release camera hardware.
* When minimizing or backgrounding the app, `didChangeAppLifecycleState` disposes the controller and cleanly re-initializes upon resuming.

### C. Graceful Fallbacks (Emulators & Desktop)
* If running on a system without a physical or virtual camera (or in headless test runners), initialization catches exceptions and displays a wireframe target box with the camera icon.
* Users can always tap **"Gallery"** to pick a photo from their device library via `ImagePicker`.

### D. GPS Location Ingestion
* When **GPS** is set to **"Auto"**, the form dynamically queries `LocationService.getCurrentPosition()`.
* If GPS hardware is active and permitted, high-accuracy latitude and longitude are recorded into the report payload. If offline or denied, it defaults to demo coordinates (`14.5995, 120.9842`).

### E. AI Preparation & Handover Hook
* Submitting a report calls the Supabase PostgreSQL RPC `create_report(...)`, saving the report with:
  * `photo_url`: Stored in Supabase `animal-photos` bucket.
  * `location`: PostGIS `geography(Point, 4326)`.
  * `analysis_status`: Initialized as `'pending'`.
* Once the report ID is returned, `ReportRepositoryImpl.requestReportAnalysis(reportId)` immediately dispatches `POST /api/reports/{id}/analyze/` via `OrchestratorClient` with the user's Supabase JWT token.
* This call is `unawaited` in the background with a safe `try-catch`, so if the Django AI container is not yet running, the report creation completes successfully without throwing an error to the user.

---

## 3. How to Test the Camera

### Option A: Physical Mobile Device (Recommended for Real Camera)

Testing on a real phone provides true camera sensor feedback:

1. Connect your Android or iOS device via USB (enable USB Debugging on Android).
2. Run `flutter devices` to verify connection.
3. Launch the app:
   ```bash
   cd mobile_app
   flutter run -d <your-device-id>
   ```
4. When prompted, grant **Camera** and **Location** permissions.

---

### Option B: Android Emulator with Virtual Camera

To test the live viewfinder in an emulator:

1. Open **Android Studio** > **Device Manager**.
2. Click the **Edit (Pencil)** icon next to your AVD (e.g. `Pixel 7` or `sdk gphone64`).
3. Click **Show Advanced Settings**.
4. Scroll to **Camera**:
   * Set **Front**: `Emulated` or `VirtualScene`.
   * Set **Back**: `VirtualScene`.
5. Start the emulator.
6. Launch the app:
   ```bash
   cd mobile_app
   flutter run
   ```
7. When the camera tab opens, the virtual 3D room will stream live inside the viewfinder brackets. Hold `Alt` (or `Option` on macOS) + `W/A/S/D` to move the camera around in the virtual room.

---

### Option C: Gallery Selection (All Platforms)

Even on emulators or simulators without virtual scenes:
1. Tap the **"Gallery"** button on the bottom-left of the viewfinder.
2. Select any sample photo of a pet from your photo album.
3. The photo will instantly preview inside the framing brackets.

---

## 4. Step-by-Step QA Checklist

| # | Action | Expected Behavior |
| :--- | :--- | :--- |
| **1** | **Open Camera Tab** | Tap the center camera button on the bottom navigation bar (`CustomAppBar`). The tab highlights and the viewfinder loads. |
| **2** | **Verify Live Stream** | The viewfinder shows the live camera feed framed inside the four corner brackets (`┌ ┐ └ ┘`). |
| **3** | **Tap Shutter Button** | Center shutter circle pulses briefly, captures the photo, and displays the static preview image inside the viewfinder. |
| **4** | **Check "Retake" Button** | A dark "Retake" button appears on the bottom-right of the preview. Tapping it discards the captured photo and returns to the live camera stream. |
| **5** | **Tap "Gallery" Button** | Opens the device photo library. Picking an image displays it in the viewfinder. |
| **6** | **Select Animal Type & Status** | Tap **ANIMAL TYPE** dropdown (*Canine*, *Feline*, *Other*) and **STATUS** (*Stray*, *Missing*, *Found*). Selection updates. |
| **7** | **Enter Description** | Type notes (e.g., "Golden retriever spotted near Central Park, red collar"). |
| **8** | **Check GPS Mode** | Toggle the **GPS** button (*Auto* / *Manual*). In Auto mode, coordinates are automatically acquired. |
| **9** | **Tap "Submit Report"** | Submit button shows a loading spinner, creates the report, and opens a success dialog ("Report Submitted"). |
| **10**| **Tap "View on Map"** | Navigates directly to the Community Animal Map (`/map`) where the new sighting marker is placed. |
| **11**| **Tab Switching Battery Check** | Switch to the Map tab or Feed tab. In device monitor / logs, verify the camera hardware preview pauses. |

---

## 5. Automated Tests

The entire camera and report widget suite can be validated in terminal CLI without needing physical hardware:

```bash
# 1. Run dedicated camera & report widget tests (5 tests)
flutter test test/camera_widget_test.dart

# 2. Run full test suite across the entire application (19 tests)
flutter test

# 3. Verify static analysis and zero lint issues
flutter analyze
```

---

## 6. Troubleshooting Common Issues

### 1. Viewfinder is black or displays the wireframe box on emulator
* **Cause**: Emulator has its back camera set to "None" in AVD settings.
* **Fix**: In Android Studio Device Manager, edit the AVD > Advanced Settings > set **Back Camera** to **VirtualScene**. Alternatively, tap the **"Gallery"** button to test with an image.

### 2. iOS Crash on Camera Tap: `NSCameraUsageDescription`
* **Cause**: iOS requires explicit privacy descriptions in `Info.plist`.
* **Fix**: Already configured! `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSMicrophoneUsageDescription` are declared in `ios/Runner/Info.plist`.

### 3. Android permission denied
* **Cause**: Runtime permissions rejected.
* **Fix**: Ensure `android.permission.CAMERA` is present in `AndroidManifest.xml` (already configured) and enable Camera under Android Settings > Apps > Paws and Found > Permissions.

### 4. AI Orchestrator connection warning in logs
* **Log**: `[ReportRepositoryImpl] AI analysis dispatch deferred (backend offline)`
* **Status**: Normal and expected when running without the Docker micro-orchestrator container. The report is safely saved in Supabase with `analysis_status: 'pending'` and will be processed when the AI container is brought online.
