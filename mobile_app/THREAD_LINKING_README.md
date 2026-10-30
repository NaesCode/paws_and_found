# Thread Creation & Sighting Link Embedding — Collaborator Guide

Welcome to the **Thread Creation & Sighting Link Embedding** architecture and testing guide for **Paws and Found**. This document provides a complete technical walkthrough for contributors and reviewers on how animal sightings can be linked into missing pet discussion threads, how deep links and embedded cards are handled, and how the frontend interacts with the Supabase database.

---

## 1. Feature Overview & Problem Solved

When an animal is reported missing, community sightings are vital. Previously, all reports were standalone posts scattered across the general feed with no direct association to the missing pet's active search thread.

With this feature:
1. **Thread Linking**: When reporting a sighting, users can link their report directly into a missing pet's discussion thread.
2. **Dual Entry Points**:
   - **From Feed Cards**: Tapping **"Spotted"** or **"Found"** on a missing pet card directly opens the camera with the thread pre-linked.
   - **From Camera Tab**: Users opening the camera standalone can tap **"Link sighting to an existing Missing Pet thread"** to pick from a list of active missing pets.
3. **Automated Thread Updates**: Upon report submission, the app automatically publishes an update comment in the pet's thread containing a deep link to the sighting (`https://pawsandfound.org/report/<report_id>`).
4. **Rich Embedded Sighting Cards**: Any comment containing a sighting link dynamically renders an interactive **`EmbeddedSightingCard`** displaying the animal thumbnail, status, reverse-geocoded locality, and a one-tap **"View on Map"** button.
5. **Deep Link Clipboard Sharing**: Users can copy a shareable link straight from the submission confirmation dialog.

---

## 2. Architecture & File Structure

This feature strictly adheres to **Clean Architecture** (separated by `presentation`, `domain`, and `data` in `lib/features/`) and **Atomic Design** (atoms, molecules, organisms in `lib/shared/`).

```text
mobile_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_assets.dart                # Centralized asset constants (petPlaceholder)
│   │   │   └── location_constants.dart        # Cebu Province GPS coordinates & bounds
│   │   └── routes/
│   │       └── app_router.dart                # Routes /camera and /report with query params
│   ├── features/
│   │   ├── feed/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── comment_model.dart     # FeedComment with regex link extraction
│   │   │   │   │   └── feed_post_model.dart   # FeedPost model with location_name parsing
│   │   │   │   └── repositories/
│   │   │   │       └── feed_repository_impl.dart # Comments fetch (with batch profiles) & post
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── feed_repository.dart   # Contract: getComments, addComment, getReportById
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── general_reports_page.dart # Wired "Spotted" & "Found" button navigation
│   │   │       │   └── personal_reports_page.dart
│   │   │       └── widgets/
│   │   │           ├── embedded_sighting_card.dart # Rich sighting widget inside comments
│   │   │           ├── feed_card_comments.dart     # Renders comments and embeds
│   │   │           ├── feed_card_footer.dart       # "Thread →" button opening discussion modal
│   │   │           ├── feed_comments_modal.dart    # Full bottom-sheet thread modal
│   │   │           └── feed_report_card_item.dart  # Forwards report ID to thread footer
│   │   └── report/
│   │       ├── presentation/
│   │       │   ├── pages/
│   │       │   │   └── camera_report_page.dart       # Linked thread banner, picker & success dialog
│   │       │   └── providers/
│   │       │       └── camera_report_controller.dart # Auto-inserts thread comment on submit
└── test/
    └── thread_linking_test.dart               # Regex extraction & comment parsing test suite
supabase/
└── migrations/
    └── 20261031000000_thread_comments_schema.sql # Comments table RLS, indexes & realtime
```

---

## 3. Detailed Component Workflows

### A. Quick Sighting from Feed Cards
1. User browses [`GeneralReportsPage`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/presentation/pages/general_reports_page.dart).
2. Tapping **"Spotted"** triggers:
   ```dart
   context.push('/camera?threadId=${report.id}&petName=${Uri.encodeComponent(report.petName)}&status=stray');
   ```
3. Tapping **"Found"** triggers:
   ```dart
   context.push('/camera?threadId=${report.id}&petName=${Uri.encodeComponent(report.petName)}&status=found');
   ```
4. [`AppRouter`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/core/routes/app_router.dart) unpacks `threadId`, `petName`, and `status`, passing them into `CameraReportPage`.

### B. In-Camera Thread Linking Banner & Thread Picker
In [`CameraReportPage`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/report/presentation/pages/camera_report_page.dart):
* **When Thread is Linked**: Displays a top banner:
  > `🐾 Linked to Missing Pet Thread: "<Pet Name>" [X]`
  - Clicking `[X]` unlinks the thread via `_controller.clearThreadContext()`.
* **When No Thread is Linked**: Displays an optional action button:
  > `🔗 Link sighting to an existing Missing Pet thread (Optional)`
  - Opens a draggable bottom sheet queries active missing pets (`FeedRepository.getGeneralReports('', filterStatus: 'missing')`).
  - Selecting a pet sets `threadId` and `petName` in [`CameraReportController`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/report/presentation/providers/camera_report_controller.dart).

### C. Report Submission & Automatic Comment Insertion
When the user submits the sighting in [`CameraReportController.submitReport()`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/report/presentation/providers/camera_report_controller.dart#L244-L326):
1. Reverse geocodes the coordinates to resolve a human-readable locality (`_geocodedAddress`, e.g., `"Lahug, Cebu City"`).
2. Submits the report to Supabase via `_repository.createReport(...)` with `locationName`.
3. If `_linkedThreadId != null`, automatically inserts a comment into `public.comments`:
   ```sql
   insert into public.comments (post_id, user_id, content) values (
     '<linked_pet_id>',
     '<current_user_id>',
     '🐾 Sighting reported for <petName> at Lahug, Cebu City!\nhttps://pawsandfound.org/report/<report_id>'
   );
   ```
4. Registers the new sighting in `MapReportModel` so it immediately appears on the Community Animal Map.
5. In development/offline/unauthenticated mode, it safely falls back to local map registration without crashing.

### D. Submission Confirmation Dialog
Upon submission, an alert dialog appears with:
* **"Copy Link"**: Copies `https://pawsandfound.org/report/<reportId>` to the device clipboard.
* **"Open Thread"** (visible if a thread was linked): Opens [`FeedCommentsModal`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/presentation/widgets/feed_comments_modal.dart) to view the new sighting in the discussion.
* **"View on Map"**: Navigates to `/map?reportId=<reportId>&lat=<lat>&lng=<lng>` centered on the pinned coordinates.
* **"Stay Here"**: Dismisses the modal.

### E. Rich Embedded Sighting Cards in Threads
* [`FeedComment`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/data/models/comment_model.dart) uses regex to inspect every comment:
  ```dart
  static final RegExp _sightingLinkRegex = RegExp(
    r'(?:https?:\/\/(?:www\.)?pawsandfound\.(?:org|app)\/report\/|pawsandfound:\/\/report\/|\/report\/)([a-f0-9\-]{36})',
    caseSensitive: false,
  );
  ```
  - Parses out `linkedReportId`.
  - Cleans the comment text into `cleanContent` (removing raw link clutter).
* [`FeedCardComments`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/presentation/widgets/feed_card_comments.dart) renders [`EmbeddedSightingCard`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/presentation/widgets/embedded_sighting_card.dart) below the comment bubble when `linkedReportId` is present.
* The card loads the sighting asynchronously via `FeedRepository.getReportById(...)` and displays:
  - 52x52 photo thumbnail (with `AppAssets.petPlaceholder` fallback).
  - Badge: `SIGHTING • <STATUS>`.
  - Animal species and reported pet name.
  - Reverse-geocoded location with pin icon.
  - Full-width **"View Sighting on Map →"** button that navigates directly to the map coordinates.

---

## 4. Supabase Database & Query Architecture

### Table: `public.comments`
```sql
create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.reports(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    parent_id uuid references public.comments(id) on delete cascade,
    content text not null check (char_length(trim(content)) > 0),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
```

### Avoiding PostgREST `PGRST200` Schema Cache Errors
Because `comments.user_id` references `auth.users(id)` and not directly `public.profiles(id)`, PostgREST throws `PGRST200` if querying `.select('*, profiles(*)')`.
To avoid this without requiring custom DB foreign-key mutations, [`FeedRepositoryImpl.getComments()`](file:///d:/User%20Files/Documents/dev%20stuff/paws_and_found/mobile_app/lib/features/feed/data/repositories/feed_repository_impl.dart#L100-L140) uses a batch-fetch pattern:
1. Queries `comments` by `post_id`.
2. Extracts unique `user_id` values.
3. Batch-queries `profiles` using `.inFilter('id', userIds)`.
4. Merges profile names and avatar URLs into the `FeedComment` instances in memory.

---

## 5. Verification & Testing

### Running Unit & Widget Tests
Run the dedicated thread linking test suite:
```bash
flutter test test/thread_linking_test.dart
```

Run all tests across the project:
```bash
flutter test
```
*Current test status: 56/56 passing tests.*

### Running Static Analysis
```bash
flutter analyze lib
```
*Current status: 0 issues found.*

---

## 6. Future Enhancements & Notes for Collaborators

1. **Supabase Realtime**:
   - `supabase/migrations/20261031000000_thread_comments_schema.sql` adds `public.comments` to `supabase_realtime`.
   - In `FeedCommentsModal`, a stream subscription can be added to receive new sightings in real time without manual pull-to-refresh.
2. **Push Notifications**:
   - When a comment containing a sighting link is inserted into `comments`, a database webhook or Edge Function can trigger a push notification to the missing pet's reporter.
3. **Deep Link Handling on Launch**:
   - The regex supports custom URI schemes (`pawsandfound://report/<id>`) and web links (`https://pawsandfound.org/report/<id>`), ready for `app_links` or `uni_links` initialization in `main.dart`.

