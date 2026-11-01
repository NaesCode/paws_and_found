# Thread Creation, In-Camera AI Pre-Matching & Sightings Dashboard — Collaborator Guide

Welcome to the **Thread Creation, In-Camera AI Pre-Matching & Sightings Dashboard** architecture and testing guide for **Paws and Found**. This document provides a complete technical walkthrough for contributors and reviewers on how animal sightings are scanned with real-time visual AI, linked directly into missing pet reports, and tracked by pet owners in a dedicated sightings dashboard.

---

## 1. Feature Overview & Problem Solved

When an animal is reported missing, community sightings are vital. Previously, all reports were standalone posts scattered across the general feed with no direct association to the missing pet's active search thread. Furthermore, AI image matching was only run in the background *after* a report had already been saved.

With this release:
1. **In-Camera Real-Time Visual AI Pre-Matching (Google Lens-Style)**:
   - When a spotter snaps or picks a photo in the camera view, the app instantly and non-blockingly triggers an AI visual comparison against active missing pets.
   - The user sees candidate match cards with visual similarity badges (e.g., `94% MATCH`), distance away, and last seen locations.
   - The user can select a candidate with a single tap to link the sighting to the missing pet before pressing submit.
2. **Ephemeral In-Memory Processing**:
   - The mobile client uploads compressed photo bytes directly via `multipart/form-data` to the orchestrator endpoint (`/api/ai/match-candidates/`).
   - The backend computes the image embedding in RAM, searches active missing pets, and discards the buffer—solving the roadblock of needing temporary storage buckets or heavy on-device neural networks.
   - If the backend endpoint is unreachable, a resilient client-side Supabase simulation fallback activates automatically.
3. **Direct Database Schema Relationship (`linked_report_id`)**:
   - Spotted reports record the parent missing pet report ID directly via `reports.linked_report_id`.
   - Populated atomically inside the `create_report` PostgreSQL RPC function.
4. **Pet Owner's Dedicated Sightings Tracking Dashboard**:
   - Replaces unstructured comment threads with a clean, dual-tab interface on feed cards:
     - **`🐾 Sightings Log (X)`**: A dedicated tracking dashboard showing spotter info, timestamp, photo thumbnail, reverse-geocoded location with pin icon, and a direct **"View Sighting on Map →"** navigation button.
     - **`💬 Community Chat (X)`**: Standard chronological discussion feed for community encouragement and search tips.
5. **Dual Query Strategy & Backwards Compatibility**:
   - `FeedRepositoryImpl.getLinkedSightings` fetches sightings directly linked via `linked_report_id = eq(reportId)` and merges any historical sightings embedded in comment URLs.
6. **Rich Embedded Sighting Cards & Deep Links**:
   - Comments containing `https://pawsandfound.org/report/<report_id>` dynamically render an interactive `EmbeddedSightingCard`.
   - Users can copy shareable sighting links directly from the submission dialog.

---

## 2. Architecture & File Structure

This feature strictly adheres to **Clean Architecture** (separated by `presentation`, `domain`, and `data` in `lib/features/`) and **Atomic Design** (atoms, molecules, organisms in `lib/shared/`).

```text
mobile_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_assets.dart                   # Centralized asset constants (petPlaceholder)
│   │   │   └── location_constants.dart           # Cebu Province GPS coordinates & bounds
│   │   ├── routes/
│   │   │   └── app_router.dart                   # Routes /camera and /report with query params
│   │   └── services/
│   │       └── ai_pre_match_service.dart         # Ephemeral multipart candidate scan & local dev fallback
│   ├── features/
│   │   ├── feed/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── comment_model.dart        # FeedComment with regex link extraction
│   │   │   │   │   └── feed_post_model.dart      # FeedPost model with location_name parsing
│   │   │   │   └── repositories/
│   │   │   │       └── feed_repository_impl.dart # Dual-query getLinkedSightings & batch-profile comments
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── feed_repository.dart      # Contract: getComments, addComment, getLinkedSightings
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   └── general_reports_page.dart # Wired "Spotted" & "Found" button navigation
│   │   │       └── widgets/
│   │   │           ├── embedded_sighting_card.dart # Rich sighting widget inside comments
│   │   │           ├── feed_card_comments.dart     # Renders comments and embeds
│   │   │           ├── feed_card_footer.dart       # "Thread →" button opening dual-tab modal
│   │   │           ├── feed_comment_input_bar.dart # Input bar active only on Chat tab
│   │   │           └── feed_comments_modal.dart    # Dual-tab modal: Sightings Log vs Community Chat
│   │   └── report/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── report_remote_datasource.dart # createReport with p_linked_report_id
│   │       │   ├── models/
│   │       │   │   └── ai_match_candidate.dart   # Candidate model with similarityScore & proximity
│   │       │   └── repositories/
│   │       │       └── report_repository_impl.dart   # ReportRepository implementation
│   │       ├── domain/
│   │       │   └── repositories/
│   │       │       └── report_repository.dart    # Contract with linkedReportId parameter
│   │       └── presentation/
│   │           ├── pages/
│   │           │   └── camera_report_page.dart   # Embeds AiMatchScannerCard & all-candidates sheet
│   │           ├── providers/
│   │           │   └── camera_report_controller.dart # Holds AI candidate state & triggers background scan
│   │           └── widgets/
│   │               └── ai_match_scanner_card.dart# Real-time visual AI scanning card & match badge
└── test/
    ├── ai_pre_match_test.dart                    # Unit tests for candidate model, thresholds & controller
    └── thread_linking_test.dart                  # Regex extraction & comment parsing test suite
supabase/
└── migrations/
    ├── 20261031000000_thread_comments_schema.sql # Comments table RLS, indexes & realtime
    └── 20261101000000_linked_report_sightings.sql# linked_report_id column & updated create_report RPC
```

---

## 3. Detailed Component Workflows

### A. Spotter In-Camera Flow (Google Lens-Style AI Pre-Matching)
1. **Capture/Pick Photo**: User snaps a picture or selects one from the gallery.
2. **Asynchronous Background AI Scan**:
   - `CameraReportController.setImageData()` immediately kicks off `unawaited(runAiPreMatchScan())`.
   - The UI never freezes; the shutter remains fully interactive.
3. **Live AI Scanner Card (`AiMatchScannerCard`)**:
   - While scanning: Displays a subtle pulsing progress indicator with *"AI Visual Scanner Active"*.
   - When matches found: Displays top visual match thumbnail, pet name, visual similarity badge (e.g., `94% MATCH`), distance, and a **"Link to <Pet>"** action button.
   - If multiple candidates exist, displays a **"+X others"** button that opens a draggable sheet to view and select any candidate.
   - When a match is selected: The card turns to a confirmed green-tint banner with an un-link `[X]` button.
   - Fallback: If no matches are found or before snapping a photo, the user can tap *"Link sighting to an existing Missing Pet report (Optional)"* to browse active missing pets manually.
4. **Report Submission**:
   - Submits report with `linked_report_id` set to the selected pet's report ID.
   - Auto-posts a sighting link into the pet's discussion comments for community visibility.
   - Pushes the new marker directly onto the Community Animal Map.

```
[In-Camera Viewfinder]
        │
  (Photo Captured)
        │
        ├──▶ Run Ephemeral AI Scan ──▶ [/api/ai/match-candidates/] ──▶ [AiMatchCandidates]
        │                                                                     │
        ▼                                                                     ▼
[Camera Report Form] ◀───────────────────────────────────────── [AiMatchScannerCard]
        │                                                      (Tap "Link to Luna")
        │
  (Submit Report)
        │
        ▼
[create_report RPC (linked_report_id = Luna's Report ID)]
```

### B. Pet Owner Sightings Log Flow
1. Pet owner or community member taps **"Thread →"** on a missing pet card.
2. [`FeedCommentsModal`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/presentation/widgets/feed_comments_modal.dart) opens with a top tab switcher:
   - **`🐾 Sightings Log (X)`** (Default):
     - Displays every sighting linked to this missing pet.
     - Each sighting card features: spotter avatar & name, relative timestamp, high-resolution photo thumbnail, reverse-geocoded location, and a prominent **"View Sighting on Map →"** button that jumps straight to the interactive map.
   - **`💬 Community Chat (X)`**:
     - Displays text comments, encouragement, and search updates.
     - The bottom comment input bar is strictly visible on this tab, keeping the Sightings Log uncluttered.

---

## 4. Supabase Database Schema

### Database Migration: `20261101000000_linked_report_sightings.sql`

```sql
-- 1. Add linked_report_id foreign key column to public.reports
alter table public.reports
    add column if not exists linked_report_id uuid references public.reports(id) on delete set null;

-- 2. Index for high-performance sightings retrieval
create index if not exists idx_reports_linked_report_id
    on public.reports(linked_report_id);

-- 3. Update create_report RPC to accept p_linked_report_id
create or replace function public.create_report(
    p_animal_type text,
    p_description text,
    p_photo_url text,
    p_lat double precision,
    p_lng double precision,
    p_status text default 'stray',
    p_pet_id uuid default null,
    p_location_name text default null,
    p_linked_report_id uuid default null
)
...
```

---

## 5. Verification & Testing

### Running Unit Tests
```bash
# Run AI Pre-Match model & controller tests alongside thread linking tests:
flutter test test/ai_pre_match_test.dart test/thread_linking_test.dart
```
*Current test status: 13/13 passing tests.*

### Running Static Analysis
```bash
flutter analyze --no-pub lib
```
*Current status: 0 issues found (No issues found!).*
