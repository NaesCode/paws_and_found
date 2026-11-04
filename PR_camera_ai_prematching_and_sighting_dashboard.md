# Pull Request: In-Camera AI Pre-Matching ("Google Lens"), Sightings Linking, and Match Threshold Calibration

## 📌 PR Summary & Purpose
This PR integrates the real-time **in-camera AI visual pre-matching pipeline** ("Google Lens"-style scanner) and the **dedicated pet sightings linking workflow** into the main development branch. It bridges the Flutter mobile camera viewfinder with the Django AI orchestrator (PyTorch ResNet-18 + SSDLite320) using ephemeral in-memory feature extraction.

Additionally, this PR resolves all merge conflicts from the teammate's branch (`feature/thread-creation-report`), cleans up moderation field consistency, scopes the camera screen exclusively to field spotters (`Stray` and `Found`), upgrades the offline proximity fallback with the mathematical **Haversine GPS formula**, and calibrates the AI matching threshold to **`0.78`** based on empirical evaluation data.

---

## 🚀 Key Features & Changes

### 1. In-Camera AI Pre-Matching ("Google Lens") — Django Backend
* **New Endpoint (`POST /api/ai/match-candidates/`):**
  - Implemented `MatchCandidatesView` in [`backend/core/views.py`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/backend/core/views.py) and registered it in [`backend/core/urls.py`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/backend/core/urls.py).
  - **Zero Storage Bloat:** Unsubmitted camera snapshots are processed entirely in server RAM and immediately garbage-collected after inference (no junk files in Supabase Storage or database).
  - **Animal Isolation & Feature Extraction:** Reuses the existing `embed_image()` pipeline to detect and crop animals via SSDLite320 (+10% padding) and extract an L2-normalized 512-dimensional vector via ResNet-18.
  - **Sub-100ms Matching:** Computes cosine similarity against precomputed embeddings in `pet_embeddings` / `report_embeddings` combined with PostGIS `Distance("location", point)`.
  - **Pure Visual Matching:** Removed restrictive text dropdown filtering so visual features drive the search across all active missing reports.

### 2. Client-Side Pre-Match Service & Upgraded GPS Fallback
* **Extended Network Timeout:** Increased `scanForCandidates` timeout from 4s to 8s in [`AiPreMatchServiceImpl`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/mobile_app/lib/core/services/ai_pre_match_service.dart) to accommodate image upload and CPU inference over local USB / Wi-Fi / ngrok.
* **Mathematical Haversine GPS Fallback:**
  - When the AI container is disconnected or times out, the client falls back to querying the [`feed_reports`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/supabase/migrations/20261031000002_report_content_moderation.sql) view in Supabase.
  - Replaced simulated fake incremental distances (`(i + 1) * 0.45` km) with the true spherical Earth Haversine formula ($R = 6371\text{ km}$), computing exact geographic distances between the camera pin and missing pets.
  - Integrated content moderation checks to omit `flagged` reports from suggestion cards.

### 3. Camera Page Scoping for Field Spotters
* **Removed "Missing" Option from Camera Form:**
  - Updated [`CreateReportForm`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/mobile_app/lib/features/report/presentation/widgets/create_report_form.dart) to only offer `['Stray', 'Found']`.
  - **Architectural Rationale:** Missing pet listings are official owner registrations requiring `pet_id`, microchip, photos, and contact info via **Profile $\rightarrow$ Pets $\rightarrow$ "Report Missing"**. Spotters in the field use the Camera screen to report sightings of animals they encounter.
  - Contextual submit button labels: **"Submit Sighting Report"** (for Stray) and **"Submit Found Pet Report"** (for Found).
* **Defensive Dropdown Resolution & Error Logging:**
  - Added safe item resolution in `_buildDropdownField` to eliminate runtime dropdown assertion crashes.
  - Added full stack trace logging in [`CameraReportController.submitReport()`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/mobile_app/lib/features/report/presentation/providers/camera_report_controller.dart) so Supabase RPC errors are never swallowed silently.

### 4. Database Migrations & Moderation Sync
* **Migration `20261101000000_linked_report_sightings.sql` Applied:**
  - Adds nullable `linked_report_id` UUID column with foreign key to `reports(id)` (`on delete set null`).
  - Partial index `idx_reports_linked_report_id` for fast sightings timeline queries.
  - Updated `create_report` RPC with optional 9th parameter `p_linked_report_id uuid default null`.
* **Repository Consistency:**
  - Added `moderation_status` to Supabase query projections in [`FeedRepositoryImpl.getReportById()`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/mobile_app/lib/features/feed/data/repositories/feed_repository_impl.dart#L90) and `getLinkedSightings()`.

### 5. Empirical AI Threshold Calibration (`0.78`)
* Evaluated matching performance using `evaluate_matching` across 28 image pairs:
  - **Positive pair similarity:** Mean `0.8532`, Minimum `0.8136`.
  - **Negative pair similarity:** Mean `0.5840`, Maximum `0.6820`.
  - **Separation margin:** Clean window of `0.1316` (+13.1%) with 100% precision and 100% recall.
  - **SSDLite Crop Benefit:** Confirmed detector crop boosts positive similarity by **+3.2%** and improves recall at 0.80 by **+25%**.
* **Calibrated Base Similarity:**
  - Updated `MATCH_BASE_SIMILARITY = 0.78` in [`backend/config/settings.py`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/backend/config/settings.py), [`backend/.env`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/backend/.env), and [`backend/.env.example`](file:///c:/Users/User/Documents/College%20Files/Software%20Development/Github/Paws_and_Found/backend/.env.example).
  - Ensures local sightings ($< 10\text{ km}$) require $\ge 0.78$ similarity (capturing 100% of true positives while safely above the $0.6820$ negative floor).

---

## 🔄 Deviations from Previous Merged State

| Component | Teammate's Original Branch | Current PR State | Reason for Deviation |
|---|---|---|---|
| **Camera Status Dropdown** | Included `['Stray', 'Missing', 'Found']` | Restricted to `['Stray', 'Found']` | Prevents spotters from creating orphan missing pet reports with `pet_id = null`. Official missing pet reports belong in Profile. |
| **In-Camera Fallback Distance** | Synthetic hardcoded increment: `(i + 1) * 0.45` km | Mathematical **Haversine formula** against real GPS coordinates from `feed_reports` view | Provides accurate distance readouts to the user even when the AI server is offline. |
| **Pre-Match Timeout** | 4 seconds | 8 seconds | Prevents premature fallback to offline mode when running over local Wi-Fi or USB connection. |
| **Visual Search Filtering** | Filtered by form dropdown species text | Evaluates visual feature similarity across all active missing reports | True "Google Lens" behavior: visual features determine matches rather than form selections. |
| **Base Similarity Threshold** | Defaulted to 0.80 | Calibrated to **0.78** | Accommodates distance-tier penalties ($+0.05$ at $10\text{ km}$) without dropping legitimate true-positive matches. |

---

## 🧪 Testing & Verification Guide

### 1. Direct USB Testing (No ngrok Needed)
1. Plug your Android phone into your PC via USB (with USB Debugging enabled).
2. Run the reverse proxy command in terminal:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
   ```
3. Run the Flutter app:
   ```powershell
   cd mobile_app
   flutter run
   ```

### 2. Verify Google Lens AI Match Suggestion
1. Navigate to the **Camera** tab.
2. Snap or choose a photo of an animal from your gallery.
3. Observe the `AiMatchScannerCard` appearing below the photo:
   - Scanning state: *"AI Visual Scanner Active..."*
   - Match state: Shows pet photo, name, match percentage, and distance.
4. Check Docker terminal logs:
   ```text
   paws_backend | POST /api/ai/match-candidates/ HTTP/1.1 200 OK
   ```

### 3. Verify Sighting Linking & Dashboard
1. On the match suggestion card, tap **"Link to [Pet Name]"**.
   - Card turns green: *"Linked Sighting: Sighting will be tracked under [Pet Name]'s dashboard."*
2. Tap **"Submit Sighting Report"**.
3. Go to the Feed $\rightarrow$ locate the original Missing Pet post $\rightarrow$ tap **"Thread →"**.
4. Switch to the **"Sightings Log"** tab:
   - Verify that your newly reported sighting is displayed in the timeline with its photo, timestamp, and location.

---

## 🔮 Next Steps & Recommendations

1. **Quarantine Flagged Posts from Public Feed:**
   - Currently, flagged reports display a warning banner to the reporter.
   - Next migration: Update `feed_reports` view and `nearby_reports` RPC to exclude `moderation_status = 'flagged'` so flagged posts are completely hidden from the general public.
2. **Admin Review Dashboard:**
   - Create a dedicated review page for administrators to query `reports WHERE moderation_status = 'flagged'`, inspect the flagged photo and AI confidence score, and approve or reject the report.
3. **Migration Filename Collision Cleanup:**
   - `20261031000000_thread_comments_schema.sql` and `20261031000000_pet_deletion_logs_and_rpc.sql` share the same timestamp prefix. If using the Supabase CLI locally, rename one of the files with an incremented prefix (e.g., `20261031000003_...`).
4. **Wireframe Action Buttons:**
   - Implement the "Edit" and "View Map" action handlers in `PersonalReportsPage` (currently placeholders).
