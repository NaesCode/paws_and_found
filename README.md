# Paws and Found 

This is the repository for Paws and Found. This guide covers everything a developer needs to build, test, and ship features for the platform. It outlines the technical specifications required to configure your local development environment and ensures a seamless workflow across the team's Flutter mobile client, Supabase backend, and OpenCV AI engine. Read this thoroughly before opening your first PR.

---

## Table of Contents
- [1. Project Setup and Prerequisites](#1-project-setup-and-prerequisites)
- [2. Backend and OpenCV Initialization](#2-backend-and-opencv-initialization)
- [3. Distributed System Architecture](#3-distributed-system-architecture)
- [4. The Event-Driven Workflow](#4-the-event-driven-workflow)
- [5. Geospatial Development & PostGIS](#5-geospatial-development--postgis)
- [6. Security and RLS](#6-security-and-rls)
- [7. Mobile State and Offline Handling](#7-mobile-state-and-offline-handling)
- [8. Branching Naming Conventions](#8-branching-naming-conventions)
- [9. Commit Message Standards](#9-commit-message-standards)
- [10. The Supabase Workflow](#10-the-supabase-workflow)
- [11. CI/CD Rules](#11-cicd-rules)
- [12. Common Commands](#12-common-commands)
- [13. Frontend Design Structure](#13-frontend-design-structure)

---

## 1. Project Setup and Prerequisites

Every team member must configure their local environment precisely to support the cross-platform mobile framework and backend services.

1. Download and install the latest Flutter SDK and Android Studio. For deveopers using Windows Home editions, you must strictly check the "Android Emulator hypervisor driver" in the Android Studio SDK Manager to ensure virtual devices run correctly.
2. Download and install Docker Desktop. This is mandatory for hosting our local Supabase instance and containerizing the external OpenCV engine.
3. Open your terminal and clone this repository using the command `git clone https://github.com/NaesCode/Paws_and_Found`.
4. Navigate into the cloned project folder and execute the command `flutter pub get` to download all necessary Dart packages.
5. Run `flutter doctor` to confirm there are no missing components in your SDK path.

## 2. Backend and OpenCV Initialization

Our architecture relies on Supabase for the PostgreSQL database and a Python container for the artificial intelligence image matching.

1. Launch Docker Desktop and ensure the Docker engine is actively running in the background.
2. Open your terminal in the project root and execute `supabase start` to spin up the PostgreSQL database, Storage buckets, and Edge Functions locally.
3. Change directories into the backend AI folder and run `docker-compose up -d` to boot the OpenCV image processing container in detached mode.
4. Confirm that the PostGIS spatial extensions and database schemas are properly loaded before attempting to render the localized community map.

## 3. Distributed System Architecture

Paws and Found's codebase is structured using a distributed, event-driven architecture. Functionality is strictly separated by concern into distinct layers:

*   **Mobile Client (Flutter):** Responsible exclusively for the user interface, hardware interaction (Camera, GPS), and rendering Mapbox components. It contains zero business logic regarding image matching or spatial calculations.
*   **Backend Orchestrator (Supabase Edge Functions):** Serves as the API gateway. These functions validate incoming payloads, orchestrate the AI matching pipeline, and handle third-party integrations like the REST SMS Gateway.
*   **AI Matching Engine (OpenCV/Python):** Runs in an isolated Docker container, receiving pre-processed images to perform bounding box detection, extract feature embeddings, and return a high-dimensional vector.
*   **Data Layer (PostgreSQL):** Utilizes the `PostGIS` extension for spatial coordinates and `pgvector` for storing and querying visual embeddings.

> [!WARNING]
> Never bypass the Edge Functions to call the OpenCV container directly from the Flutter client. Exposing the AI engine directly to the mobile app will compromise our architecture and leak third-party API limits.

## 4. The Event-Driven Workflow

This relies on an **Event-Driven Storage Trigger** pattern as the primary mutation path to minimize the processing burden on the user's mobile device.

```text
User Interaction (Spotted Stray)
  → Flutter captures Image + GPS and uploads to Supabase Storage
    → Storage Webhook triggers an Edge Function
      → Edge Function routes payload to OpenCV Docker Container
        → OpenCV extracts feature vector and returns it
          → Edge Function performs PostGIS radius query + Cosine Similarity check
            → If threshold met (>85%), trigger REST SMS Gateway

```

This workflow ensures there are no mobile bottlenecks, provides fail-safe processing if the OpenCV container is temporarily rate-limited, and secures external API credentials from the client.

## 5. Geospatial Development & PostGIS

Paws and Found is heavily dependent on location. We do not store coordinates as basic floats; we use PostGIS to enable complex spatial mathematics at the database level. Every `Report` and `Pet` record stores location as a native `Geography(Point, 4326)` column.

When querying for reports within a specific user's vicinity, **never** fetch all records and filter them in Dart. You must utilize the `ST_DWithin` PostGIS function via our RPC endpoints.

```sql
-- Example: Finding active missing pets within 5km of a new stray report
SELECT * FROM pets
WHERE status = 'Missing'
AND ST_DWithin(
  last_known_location, 
  ST_SetSRID(ST_MakePoint(report_long, report_lat), 4326), 
  5000 -- meters
);

```

## 6. Security and RLS

Paws and Found follows a **default-deny** security architecture. No pet data or user profile is accessible unless an explicit Row Level Security (RLS) policy grants it.

1. **Supabase Auth** assigns a unique `uid()` to every registered user via JWT.
2. **Public Map Data:** The `reports` table allows public read access but explicitly masks exact street addresses, snapping them to an approximate radius to protect finder privacy.
3. **Private Matches:** The `matches` table is strictly scoped. A user can only view a match if their `auth.uid()` matches the `owner_user_id` of the pet or the `reporter_user_id` of the sighting.

To prevent pet theft, contact information is completely locked by RLS until the `status` of a match changes to `Confirmed` by a system administrator after manual ownership verification.

## 7. Mobile State and Offline Handling

Because stray reporting often happens in areas with poor cellular connectivity, the Flutter application must fail gracefully.

1. **Capture First:** The app writes the photo and GPS coordinates to local device storage using SQLite/Hive immediately.
2. **Connectivity Check:** Before attempting a Supabase Storage upload, check the network state.
3. **Queueing:** If offline, the report enters a "Pending Sync" state on the dashboard. A background worker will automatically push the payload to Supabase once a stable connection is re-established.

## 8. Branching Naming Conventions

To prevent merge conflicts before our strict November code freeze, absolutely no one is allowed to push directly to the main branch. Always create a new branch for your specific task using the prefixes outlined below.

| Branch Prefix | Usage | Example |
| --- | --- | --- |
| `feature/` | Developing new core components | `feature/opencv-matching` |
| `bugfix/` | Resolving issues from the GitHub tracker | `bugfix/map-crash` |
| `ui/` | Frontend updates and Flutter layout tweaks | `ui/feed-screen` |
| `docs/` | Updating the SDD, SPMP, or README | `docs/update-setup` |

## 9. Commit Message Standards

Clear commit messages are vital for tracking our progress against the project schedule. Every commit must follow standard conventions.

| Type | Example |
| --- | --- |
| **feat:** | feat: integrate OpenCV similarity scoring |
| **fix:** | fix: resolve PostGIS spatial query timeout |
| **chore:** | chore: update Flutter dependencies |
| **refactor:** | refactor: optimize Supabase storage triggers |

## 10. The Supabase Workflow

### Local Commands

```bash
npm run db:start      # Start all Supabase containers locally
npm run db:reset      # Drop and rebuild from migrations + seed.sql
npm run db:test       # Run pgTAP tests in supabase/tests/
npm run db:lint       # Lint SQL migrations

```

After `npm run db:start`, Supabase Studio is available at http://127.0.0.1:54323.

### Adding Database Changes

> [!IMPORTANT]
> Never make schema changes through the Supabase Studio dashboard. All changes must go through migration files to ensure consistency across the team.

```bash
# 1. Create a timestamped migration file
supabase migration new rls_for_matches

# 2. Write your SQL in supabase/migrations/<timestamp>_rls_for_matches.sql

# 3. Apply locally
npm run db:reset

```

## 11. CI/CD Rules

Every PR targeting the `main` branch triggers parallel GitHub Actions. All checks must pass before a merge is permitted to ensure we hit our strict late-November code freeze.

### Job 1: Flutter Client Validation

| Step | Command | What It Checks |
| --- | --- | --- |
| Lint | `flutter analyze` | Dart strict mode and syntax rules |
| Test | `flutter test` | Widget tests and UI logic |
| Build | `flutter build apk` | Ensures the Android binary compiles successfully |

### Job 2: Backend and AI Validation

| Step | Command | What It Checks |
| --- | --- | --- |
| Start stack | `supabase start` | Boots Postgres + PostGIS locally |
| Reset DB | `supabase db reset` | Migrations apply cleanly from scratch |
| Build AI | `docker build .` | Ensures the OpenCV Python container compiles |

## 12. Common Commands

| Command | Description |
| --- | --- |
| `flutter run` | Start the mobile app on an emulator/device |
| `flutter pub get` | Fetch Dart dependencies |
| `docker-compose up -d` | Boot the OpenCV AI image processing container |
| `supabase start` | Start the local Supabase stack |
| `supabase stop` | Stop local Supabase containers |
| `supabase migration new <name>` | Create a new database migration file |

## 13. Frontend Design Structure

The `mobile_app/lib/` directory is strictly organized into three main pillars: **Feature-Driven Architecture**, **Clean Architecture**, and **Atomic Design**.

*   **`core/`**: App-wide configurations and setup (e.g., global themes, API clients, app routing). Code here is global and not tied to any specific UI feature.
*   **`shared/`**: Global UI components built using **Atomic Design** (`atoms/`, `molecules/`, `organisms/`, `templates/`). If a widget is used in multiple features, it belongs here. Never place business logic (like API calls) inside these components.
*   **`features/`**: Independent, domain-specific modules containing the actual app logic and screens (e.g., `auth/`, `map/`, `report/`).

### The Layers within a Feature

Inside each feature folder (e.g., `features/auth/`), we follow **Clean Architecture**:

1. **`domain/` (The Business Logic)**
    *   `entities/`: Plain Dart classes representing the data.
    *   `repositories/`: Interfaces that define what data operations are possible.
    *   `usecases/`: Specific actions the app can take.
2. **`data/` (The External Connections)**
    *   `datasources/`: Classes performing API calls or DB queries.
    *   `models/`: Data classes with `fromJson`/`toJson` extending domain entities.
    *   `repositories/`: Implementations of the interfaces defined in the domain layer.
3. **`presentation/` (The UI)**
    *   `pages/`: Full screen views.
    *   `widgets/`: UI components used *only* within this feature.
    *   `providers/`: State management (BLoCs/Providers).

> **Note:** For more in-depth details regarding the frontend design structure, widget placement, and architecture rules, please visit the dedicated [Frontend Architecture Guide](./mobile_app/README.md) inside the `mobile_app` folder.
