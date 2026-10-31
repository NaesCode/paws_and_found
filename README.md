# Paws and Found

**Paws and Found** is a mobile platform for community-based stray and missing animal reporting. Users report sightings with geolocation and photos, view community activity on an interactive map, and leverage an integrated computer vision feature-matching model to compare submitted animal photos against missing pets.

The system uses a **Hybrid Architecture**:
- **Supabase Cloud** serves as the unified backend for PostgreSQL + PostGIS, Authentication, File Storage, and real-time updates. The Flutter client queries Supabase directly for fast, low-latency CRUD and spatial queries.
- **Django REST Framework** acts as a lean **micro-orchestrator** containerized in Docker, dedicated strictly to AI feature extraction, spatial candidate matching, and automated notifications.

---

## Table of Contents
- [1. System Architecture & Tech Stack](#1-system-architecture--tech-stack)
- [2. How Authentication & Identity Work](#2-how-authentication--identity-work)
- [3. Project Setup & Prerequisites](#3-project-setup--prerequisites)
- [4. Backend (Django Micro-Orchestrator) Setup](#4-backend-django-micro-orchestrator-setup)
- [5. Database & Migration Workflow (Supabase CLI)](#5-database--migration-workflow-supabase-cli)
- [6. Mobile App Setup (Flutter)](#6-mobile-app-setup-flutter)
- [7. Geospatial Architecture (PostGIS & GeoDjango)](#7-geospatial-architecture-postgis--geodjango)
- [8. Data Dictionary & Field Renaming Reference](#8-data-dictionary--field-renaming-reference)
- [9. Security Guidelines](#9-security-guidelines)
- [10. Branching & Commit Conventions](#10-branching--commit-conventions)
- [11. Common Commands Reference](#11-common-commands-reference)
- [12. Frontend Architecture Guide](#12-frontend-architecture-guide)

---

## 1. System Architecture & Tech Stack

```text
┌────────────────────────────────────────────────────────┐
│               Flutter Mobile App (Client)              │
└───────────┬────────────────────────────────┬───────────┘
            │                                │
            │ Direct Reads/Writes & Auth      │ POST /api/.../analyze/
            │ (PostgREST, GoTrue, Storage)    │ (JWT Authenticated)
            ▼                                ▼
┌────────────────────────┐       ┌────────────────────────┐
│     Supabase Cloud     │       │ Django Orchestrator    │
│  - PostgreSQL + PostGIS│       │ (Docker Container)     │
│  - GoTrue Auth         │       │ - PyTorch / OpenCV     │
│  - 'animal-photos' S3  │ ◀──── │ - Candidate Matching   │
│  - Row Level Security  │  Pool │ - GeoDjango            │
└────────────────────────┘  Conn └────────────────────────┘
```

| Component | Technology | Description |
| --- | --- | --- |
| **Mobile Client** | Flutter 3 (Dart 3) | Cross-platform app structured with Clean Architecture and Atomic Design. Queries Supabase directly. |
| **Database & Auth** | Supabase Cloud (PostgreSQL 16 + PostGIS) | Managed Postgres database with spatial indexing, Row Level Security (RLS), and JWT auth. |
| **Micro-Orchestrator** | Django 5 + DRF (Dockerized) | Headless backend for heavy geospatial candidate queries and PyTorch AI photo analysis. |
| **Image Storage** | Supabase Storage (`animal-photos`) | Public CDN storage bucket for pet profiles and sighting report images. |
| **AI / Matching** | PyTorch (CPU) + OpenCV + NumPy | Visual feature extractor and cosine similarity engine generating image embeddings. |

---

## 2. How Authentication & Identity Work

Django **never** stores or manages user passwords. Authentication is handled cleanly through Supabase Auth:

1. **Sign Up / Sign In:** The Flutter client calls Supabase Auth directly via `supabase_flutter`. On sign-up, Flutter passes `data: {'name': name}` as user metadata.
2. **Automatic Profile Provisioning:** A database trigger (`on_auth_user_created`) in Supabase automatically inserts a matching row into `public.profiles` using the user's UUID and metadata. No backend code is needed for registration.
3. **Authorized Client Calls:** Flutter attaches the user's JWT to all direct Supabase queries, where PostgreSQL **Row Level Security (RLS)** restricts data access to authorized rows only.
4. **Orchestrator Requests:** When requesting AI analysis, Flutter passes the same Supabase JWT:
   ```http
   Authorization: Bearer <supabase_access_token>
   ```
   Django's `SupabaseJWTAuthentication` validates asymmetric ES256/RS256 tokens using the project's JWKS keys (or legacy HS256 secret) and populates `request.user` with a verified `SupabaseUser`.

---

## 3. Project Setup & Prerequisites

Workstation requirements:
1. **Flutter SDK (3.13+) & Android Studio:** Configured with Android SDK and an Android Emulator.
2. **Docker Desktop:** Runs the containerized Django orchestrator.
3. **Node.js / npx:** Runs the Supabase CLI (`npx supabase`) for migrations.
4. **Supabase Cloud Project:** Contains the database schema, Auth, and `animal-photos` storage bucket.

Clone the repository:
```bash
git clone https://github.com/NaesCode/paws_and_found.git
cd paws_and_found
```

---

## 4. Backend (Django Micro-Orchestrator) Setup

The Django orchestrator connects to Supabase Cloud using the dedicated `django_backend` role through the **Session Pooler**.

1. **Configure Environment Variables:**
   ```bash
   cd backend
   cp .env.example .env
   ```
   Fill in your connection details from the Supabase Dashboard (**Project Settings > Database > Connection string > Session pooler**):
   ```env
   DB_HOST=aws-0-<region>.pooler.supabase.com
   DB_PORT=5432
   DB_USER=django_backend.<project-ref>
   DB_PASSWORD=<your-django-backend-password>
   DB_NAME=postgres
   DB_SSLMODE=require
   SUPABASE_URL=https://<project-ref>.supabase.co
   ```

2. **Start the Django Container:**
   From the repository root:
   ```bash
   docker compose up -d --build
   ```
   This spins up the single `paws_backend` container on port `8000`.

3. **Verify Connectivity:**
   ```bash
   # Check the health endpoint
   curl -I http://localhost:8000/api/health/
   ```
   *(Returns 401 when unauthenticated, confirming the JWT authentication filter is active).*

> [!NOTE]
> All application models in `backend/core/models.py` have `managed = False`. Django **never** creates or alters application tables; it only manages internal DRF/auth tables in the isolated `django` database schema.

---

## 5. Database & Migration Workflow (Supabase CLI)

The single source of truth for the database schema is [`supabase/migrations/`](./supabase/migrations/).

### Schema Development Workflow

1. **Create a new migration:**
   ```bash
   npx supabase migration new <descriptive_name>
   ```
   This creates a timestamped SQL file in `supabase/migrations/`.

2. **Test locally (Optional):**
   ```bash
   npx supabase start
   npx supabase db reset
   ```

3. **Deploy migrations to Supabase Cloud:**
   ```bash
   npx supabase login
   npx supabase link --project-ref <your-project-ref>
   npx supabase db push
   ```

### Database Security Model
- **`public` schema:** Contains user-accessible tables (`profiles`, `pets`, `reports`, `matches`, `notifications`). Protected by RLS: `anon` has zero access; `authenticated` users can read/modify only their owned records.
- **`private` schema:** Contains vector embeddings (`private.pet_embeddings`, `private.report_embeddings`). **Invisible to Flutter clients**; accessible only by the `django_backend` role.
- **`django` schema:** Holds Django's internal administrative tables, isolated from user data.

---

## 6. Mobile App Setup (Flutter)

1. Navigate to the mobile app directory:
   ```bash
   cd mobile_app
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis:
   ```bash
   flutter analyze
   ```
4. Start the application:
   ```bash
   flutter run
   ```

> [!NOTE]
> **Android Emulator Networking:**
> The Android emulator connects to your host machine's localhost via **`10.0.2.2`**. The orchestrator endpoint is configured at `http://10.0.2.2:8000/api/`. On a physical device, update `DJANGO_BASE_URL` with your workstation's LAN IP.

### Test Accounts for Development & QA

For rapid local testing without having to register new email addresses or verify inboxes, three pre-seeded dummy accounts are available on Supabase Auth (`email_confirm: true`):

| Account Role | Email | Password | Profile Status | Suggested QA Use Cases |
| :--- | :--- | :--- | :--- | :--- |
| **Pet Owner** | `petowner.test@pawsandfound.com` | `PawsTest2026!` | **Complete** (Phone & Address set) | Registering pets, reporting pets missing, viewing owned pets |
| **Stray Finder / Rescuer** | `strayfinder.test@pawsandfound.com` | `PawsTest2026!` | **Complete** (Phone & Address set) | Reporting sightings on map, feed interactions, cross-user matching |
| **New User** | `newuser.onboarding@pawsandfound.com` | `PawsTest2026!` | **Incomplete** (No phone/address) | Testing first-time login and profile completion onboarding flow |

---

## 7. Geospatial Architecture (PostGIS & GeoDjango)

All geospatial coordinates are stored as WGS84 geography points (`geography(Point, 4326)`).

### Client Spatial Operations (PostGIS RPCs)
Flutter avoids raw WKB binary parsing by invoking database-level Stored Procedures via `supabase.rpc()`:
* **`nearby_reports(lat, lng, radius_m, animal_type, lim)`**: Returns reports within the radius sorted by distance with computed `lat`, `lng`, and `distance_m` values.
* **`create_report(animal_type, description, photo_url, lat, lng, ...)`**: Atomically constructs `ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography` and returns the new report ID.
* **`report_pet_missing(p_pet_id, p_lat, p_lng)`**: Sets status to `missing`, updates last known location, and opens an alert.
* **`mark_pet_safe(p_pet_id)`**: Sets status to `safe` and clears last known location.

### Backend Candidate Matching (GeoDjango)
The Django orchestrator uses spatial indexes for fast proximity filtering during AI matching:
```python
from django.contrib.gis.measure import D
from core.models import Pet

# Find missing pets within radius excluding the reporter's own pets
candidates = Pet.objects.filter(
    status='missing',
    last_known_location__dwithin=(report_location, D(m=settings.MATCH_SEARCH_RADIUS_M))
).exclude(owner_id=reporter_id)
```

---

## 8. Data Dictionary & Field Renaming Reference

During the hybrid migration, all database columns and Django models were migrated from legacy `camelCase` to standard PostgreSQL `snake_case`. Use this table for updating the Software Design Document (SDD):

| Entity / Domain | Legacy Field (Django v1) | Current Schema Column | Type | RLS / Visibility |
|---|---|---|---|---|
| **User Profile** | `userID` | `profiles.id` | `UUID (PK, FK auth.users)` | Owner Read/Update |
| | `fullName` | `profiles.name` | `TEXT` | Authenticated Read |
| | `email` | `profiles.email` | `TEXT` | Owner Read |
| | `phoneNumber` | `profiles.phone_number` | `TEXT` | Owner Read/Update |
| | `profilePhotoURL` | `profiles.profile_photo_url` | `TEXT` | Authenticated Read |
| | `bio` *(added)* | `profiles.bio` | `TEXT` | Authenticated Read |
| | `address` *(added)* | `profiles.address` | `TEXT` | Owner Read/Update |
| | `dateRegistered` | `profiles.created_at` | `TIMESTAMPTZ` | Authenticated Read |
| **Pet** | `petID` | `pets.id` | `UUID (PK)` | Authenticated Read |
| | `ownerUserID` | `pets.owner_id` | `UUID (FK profiles)` | Owner Update/Delete |
| | `name` | `pets.name` | `TEXT` | Authenticated Read |
| | `species` | `pets.species` | `TEXT` | Authenticated Read |
| | `breed` | `pets.breed` | `TEXT` | Authenticated Read |
| | `color` | `pets.color` | `TEXT` | Authenticated Read |
| | `description` | `pets.description` | `TEXT` | Authenticated Read |
| | `photoURLs` | `pets.photo_urls` | `TEXT[]` | Authenticated Read |
| | `lastKnownLocation` | `pets.last_known_location` | `GEOGRAPHY(Point, 4326)` | Authenticated Read |
| | `status` | `pets.status` | `TEXT ('safe' / 'missing')` | Owner Update via RPC |
| | `createdAt` | `pets.created_at` | `TIMESTAMPTZ` | Authenticated Read |
| **Report** | `reportID` | `reports.id` | `UUID (PK)` | Authenticated Read |
| | `reporterUserID` | `reports.reporter_id` | `UUID (FK profiles)` | Reporter Update/Delete |
| | `petID` | `reports.pet_id` | `UUID (FK pets, nullable)`| Authenticated Read |
| | `animalType` | `reports.animal_type` | `TEXT` | Authenticated Read |
| | `description` | `reports.description` | `TEXT` | Authenticated Read |
| | `photoURL` | `reports.photo_url` | `TEXT` | Authenticated Read |
| | `location` | `reports.location` | `GEOGRAPHY(Point, 4326)` | Read via `nearby_reports` |
| | `status` | `reports.status` | `TEXT ('stray' / 'found')` | Authenticated Read |
| | `analysisStatus` | `reports.analysis_status` | `TEXT ('pending' / ...)` | Authenticated Read |
| | `createdAt` | `reports.created_at` | `TIMESTAMPTZ` | Authenticated Read |
| **Match** | `matchID` | `matches.id` | `UUID (PK)` | Reporter or Owner |
| | `reportID` | `matches.report_id` | `UUID (FK reports)` | Reporter or Owner |
| | `petID` | `matches.pet_id` | `UUID (FK pets)` | Reporter or Owner |
| | `confidenceScore` | `matches.similarity_score` | `FLOAT8` | Reporter or Owner |
| | `matchStatus` | `matches.status` | `TEXT ('potential' / ...)`| Reporter or Owner |
| | `createdAt` | `matches.created_at` | `TIMESTAMPTZ` | Reporter or Owner |
| **Notification** | `notificationID` | `notifications.id` | `UUID (PK)` | User Read/Update |
| | `userID` | `notifications.user_id` | `UUID (FK profiles)` | User Read/Update |
| | `notificationType`| `notifications.type` | `TEXT` | User Read |
| | `message` | `notifications.message` | `TEXT` | User Read |
| | `relatedMatchID` | `notifications.related_match_id` | `UUID (FK matches)` | User Read |
| | `isRead` | `notifications.is_read` | `BOOLEAN` | User Update |
| | `createdAt` | `notifications.created_at` | `TIMESTAMPTZ` | User Read |
| **AI Vectors** | `featureVector` | `private.pet_embeddings` | `FLOAT8[]` | **Backend Only** |
| | `featureVector` | `private.report_embeddings` | `FLOAT8[]` | **Backend Only** |

---

## 9. Security Guidelines

1. **Zero Secrets in Client Code:** Never embed database credentials, service-role keys, or JWT secrets in Flutter. Only the public Supabase `publishableKey` (anon key) is permitted in client builds.
2. **Database Row Level Security (RLS):** All tables have RLS enabled. Direct CRUD operations from the client are restricted to rows owned by `auth.uid()`.
3. **Dedicated Orchestrator Role:** Django connects strictly as `django_backend`, never as `postgres` or superuser.
4. **Private Embedding Isolation:** Vector embeddings reside in the `private` schema and are completely blocked from PostgREST client exposure.

---

## 10. Branching & Commit Conventions

Work on feature branches; avoid pushing directly to `main`:

| Branch Prefix | Usage | Example |
| --- | --- | --- |
| `feature/` | Developing new features | `feature/notifications-inbox` |
| `bugfix/` | Fixing defects or issues | `bugfix/appbar-theme-contrast` |
| `ui/` | Layout and design improvements | `ui/profile-appbar-unification` |
| `docs/` | Documentation & specifications | `docs/hybrid-architecture-sdd` |

Commits must follow Conventional Commits:
* `feat: implement notifications repository and screen`
* `fix: correct null-aware collection element syntax`
* `docs: update readme with hybrid architecture and data dictionary`

---

## 11. Common Commands Reference

| Task | Command | Location |
| --- | --- | --- |
| Start Django orchestrator | `docker compose up -d` | Repository root |
| Rebuild Django container | `docker compose up -d --build` | Repository root |
| View orchestrator logs | `docker compose logs -f backend` | Repository root |
| Stop orchestrator | `docker compose down` | Repository root |
| Push schema to Supabase Cloud | `npx supabase db push` | Repository root |
| Create new migration file | `npx supabase migration new <name>` | Repository root |
| Run Flutter mobile app | `flutter run` | `mobile_app/` |
| Analyze Flutter code | `flutter analyze` | `mobile_app/` |
| Fetch Flutter dependencies | `flutter pub get` | `mobile_app/` |

---

## 12. Frontend Architecture Guide

The `mobile_app/lib/` codebase strictly follows **Feature-Driven Clean Architecture** and **Atomic Design**:

* **`core/`**: App-wide global utilities, theme ([`app_theme.dart`](./mobile_app/lib/core/theme/app_theme.dart)), routing ([`app_router.dart`](./mobile_app/lib/core/routes/app_router.dart)), and orchestrator network client.
* **`shared/`**: Reusable design system widgets categorized into `atoms/`, `molecules/`, `organisms/`, and `templates/`. These components are strictly "dumb" and contain no business logic or API calls.
* **`features/`**: Self-contained domain modules (`auth/`, `profile/`, `report/`, `notifications/`, `dashboard/`) separated into:
  1. **`domain/`**: Pure entities and repository interfaces.
  2. **`data/`**: Supabase remote datasources, model serialization, and repository implementations.
  3. **`presentation/`**: Pages, feature widgets, and state controllers.

For full frontend architecture guidelines, refer to [`mobile_app/README.md`](./mobile_app/README.md).
