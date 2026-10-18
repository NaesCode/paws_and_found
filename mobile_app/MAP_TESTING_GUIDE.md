# Community Animal Map — Testing & Architecture Guide

Welcome to the **Community Animal Map** guide for **Paws and Found**. This document explains how the map subsystem is built, how spatial data flows through Clean Architecture and Atomic Design, and how to verify and test the feature end-to-end.

---

## 1. Architectural Overview

The map feature is built using **[`flutter_map`](https://pub.dev/packages/flutter_map)** and **[`latlong2`](https://pub.dev/packages/latlong2)**, fully decoupled following **Clean Architecture** and **Atomic Design**.

### Directory Structure

```text
mobile_app/
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   └── location_service.dart       # Core GPS hardware & permission service
│   │   └── routes/
│   │       └── app_router.dart             # Route registry (public /map access)
│   ├── shared/
│   │   ├── atoms/
│   │   │   ├── map_pin_badge.dart          # 'M', 'S', 'F' status-colored pins
│   │   │   └── user_location_marker.dart   # GPS blue dot with accuracy aura
│   │   ├── molecules/
│   │   │   ├── map_filter_bar.dart         # "All", "For You", "Animal Type" pills
│   │   │   └── map_legend.dart             # Status code indicator legend
│   │   ├── organisms/
│   │   │   ├── interactive_map_canvas.dart # FlutterMap tile layer + marker layer
│   │   │   ├── map_report_card.dart        # Floating animal sighting preview
│   │   │   └── custom_app_bar.dart         # Finalized bottom navigation bar
│   │   └── templates/
│   │       └── map_screen_template.dart    # Structural layout slots for the map
│   └── features/
│       └── map/
│           ├── data/                       # Models & Supabase PostGIS data sources
│           ├── domain/                     # Entities & Repository contracts
│           └── presentation/
│               ├── pages/map_page.dart     # Main Map Screen coordinator
│               └── providers/
│                   └── map_controller.dart # Reactive state controller (ChangeNotifier)
└── test/
    ├── map_widget_test.dart                # Widget tests for map atoms, organisms & page
    └── location_service_test.dart          # Unit tests for GPS service & permission states
```

---

## 2. How the Mapping Subsystem Works

### A. OpenStreetMap Tile Layer
* Unlike Google Maps, which uses platform-native SDKs, `flutter_map` renders tile images directly via Flutter's canvas engine.
* **Tile Provider**: Standard OpenStreetMap raster tiles (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
* **Compliance**: Includes `userAgentPackageName: 'com.pawsandfound.mobile_app'` in tile requests to satisfy OSM Foundation usage requirements.

### B. True Flutter Widget Markers
* Markers on `InteractiveMapCanvas` are standard Flutter widgets (`MapPinBadge`), **not static bitmap images**.
* Tapping a marker changes its visual state (`isSelected: true`), smoothly moves the map camera, and opens the floating `MapReportCard`.

### C. Hardware GPS & Permission Handling
* Device tracking is encapsulated inside `LocationService` (`lib/core/services/location_service.dart`):
  1. Calls `Geolocator.isLocationServiceEnabled()` to ensure the hardware chip is active.
  2. Requests runtime permissions gracefully without crashes.
  3. Uses `LocationAccuracy.high` and a **15-meter distance filter** to eliminate GPS jitter.
  4. Requires `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `INTERNET` permissions in `AndroidManifest.xml`.

### D. Data Fallback
* If Supabase is unreachable or in offline mode, `MapRemoteDataSourceImpl` falls back to high-fidelity mock data clustered around realistic coordinates (Metro Manila: `14.5995, 120.9842`).

---

## 3. How to Test the Map

### Option A: Run in Android Studio (Recommended)

1. **Open Project**:
   * Open Android Studio.
   * Select `File` > `Open` and choose the `paws_and_found/mobile_app` folder.
2. **Start the Emulator**:
   * Open `Device Manager` (toolbar right or `Tools` > `Device Manager`).
   * Start your virtual device (e.g. `iPhone_15` / `sdk gphone16k x86 64`).
3. **Run the App**:
   * Make sure your virtual device is selected in the top dropdown.
   * Click **Run ▶** (or press `Shift + F10`).
   * The app boots directly to `/map` by default.

### Option B: Run via Terminal CLI

From the `mobile_app` directory:

```bash
# List connected devices
flutter devices

# Run directly on the active Android emulator
flutter run -d emulator-5554

# Or run in Chrome browser
flutter run -d chrome
```

---

## 4. Interactive QA Checklist

When the map loads on your screen, verify the following interactions:

| # | Action | Expected Result |
| :--- | :--- | :--- |
| **1** | **Pan & Drag** | The map drags smoothly across streets and landmarks. |
| **2** | **Pinch / Double-Click Zoom** | Zoom level increases/decreases with tiles loading dynamically. |
| **3** | **Tap a Pin Marker ('M', 'S', or 'F')** | The badge expands with a dark ring, the camera centers on the pin, and the bottom `MapReportCard` pops up. |
| **4** | **Tap Map Background** | Deselects the active report card. |
| **5** | **Filter: "For You"** | Filters the reports according to the user's pet profile preferences. |
| **6** | **Filter: "Animal Type ▼"** | Opens bottom sheet allowing filtering by *Canine*, *Feline*, or *All*. |
| **7** | **Tap "Find My Location" Button** | Prompts for location permission (if first time), displays the blue `UserLocationMarker`, and re-centers the map. |
| **8** | **Bottom Navigation Bar** | The finalized `CustomAppBar` remains docked at the bottom with slate pill active highlights. |

---

## 5. Automated Tests

Run the dedicated automated test suite to verify code contracts and widget rendering:

```bash
# 1. Run Map widget and integration tests (12 tests)
flutter test test/map_widget_test.dart

# 2. Run LocationService unit tests (2 tests)
flutter test test/location_service_test.dart

# 3. Run full test suite across the entire project (19 tests)
flutter test

# 4. Verify static analysis and zero lint issues
flutter analyze
```

---

## 6. Troubleshooting Common Issues

### 1. `Android emulator exited with code 1 during startup`
* **Cause**: An existing emulator process crashed or was left running in the background, leaving lock files in `.android/avd/`.
* **Fix**:
  ```powershell
  Stop-Process -Name qemu-system-x86_64, emulator -Force
  Remove-Item -Path "$env:USERPROFILE\.android\avd\*.avd\*.lock" -Recurse -Force
  ```

### 2. Location permission error in debug console
* **Cause**: Manifest missing permissions.
* **Fix**: Ensure `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `INTERNET` are declared in `android/app/src/main/AndroidManifest.xml` (already configured on this branch).

### 3. OpenStreetMap tile warning in logs
* **Cause**: `[flutter_map]` logs an informational notice about OSM tile server policies.
* **Status**: Normal and expected. We have already supplied `userAgentPackageName: 'com.pawsandfound.mobile_app'` to comply with the policy.
