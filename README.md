# Paws and Found

**Paws and Found** is a mobile platform for community-based stray and missing animal reporting. Users report sightings with geolocation and photos, view community activity on an interactive Mapbox map, and leverage an integrated computer vision feature-matching model to compare submitted animal photos against missing pets.

This guide outlines the system architecture and local setup across the **Flutter mobile client**, the **Django REST Framework backend**, the **PostgreSQL + PostGIS database**, and **Supabase (Auth & Storage)**.

---

## Table of Contents
- [1. System Architecture & Tech Stack](#1-system-architecture--tech-stack)
- [2. How Authentication Works](#2-how-authentication-works)
- [3. Project Setup & Prerequisites](#3-project-setup--prerequisites)
- [4. Backend & Database Initialization](#4-backend--database-initialization)
- [5. Mobile App Setup (Flutter)](#5-mobile-app-setup-flutter)
- [6. Geospatial Development (PostGIS & GeoDjango)](#6-geospatial-development-postgis--geodjango)
- [7. Security Guidelines](#7-security-guidelines)
- [8. Branching & Commit Conventions](#8-branching--commit-conventions)
- [9. Common Commands Reference](#9-common-commands-reference)
- [10. Frontend Architecture Guide](#10-frontend-architecture-guide)

---

## 1. System Architecture & Tech Stack

```text
┌────────────────────────┐         REST (JSON over HTTPS)         ┌────────────────────────┐
│     Flutter Mobile     │ ─────────────────────────────────────▶ │  Django + DRF Backend  │
│      App (Client)      │ ◀───────────────────────────────────── │    (Business Logic)    │
└───────────┬────────────┘                                        └───────────┬────────────┘
            │                                                                 │
            │ Direct SDK Calls                                                │ ORM Queries
            ▼                                                                 ▼
    ┌───────────────┐     ┌───────────────┐                       ┌────────────────────────┐
    │ Supabase Auth │     │  Mapbox Maps  │                       │  PostgreSQL + PostGIS  │
    │ (Sign up/in)  │     │  (Vector Map) │                       │     (Docker Engine)    │
    └───────────────┘     └───────────────┘                       └────────────────────────┘
```

| Component | Technology | Description |
| --- | --- | --- |
| **Mobile Client** | Flutter (Dart 3) | Cross-platform mobile app structured with Feature-Driven Clean Architecture & Atomic Design. |
| **Backend API** | Django 5 + Django REST Framework | Handles business logic, data serialization, user management, and AI matching coordination. |
| **Database** | PostgreSQL 16 + PostGIS 3.4 | Containerized database (`postgis/postgis:16-3.4`) supporting spatial queries (`PointField`, `ST_DWithin`). |
| **Authentication** | Supabase Auth | Manages identity, password verification, and issues signed JWTs. |
| **Image Storage** | Supabase Storage | Hosts animal photos in a secure private bucket (`animal-photos`). |
| **AI / Matching** | PyTorch (CPU) + OpenCV | Pretrained visual feature extractor generating vector embeddings for photo similarity checks. |
| **Maps** | Mapbox Maps Flutter SDK | Client-side map rendering and geospatial pinpointing. |

---

## 2. How Authentication Works

Django **never** verifies or stores user passwords. Authentication is handled cleanly through Supabase Auth:

1. **Sign Up / Log In:** The Flutter client calls Supabase Auth directly via `supabase_flutter`. Supabase validates the credentials and returns a session containing an `access_token` (JWT).
   > [!IMPORTANT]
   > During registration, the Flutter app **must** pass `data: {'name': name}` to Supabase `signUp()`. Django reads this metadata on first contact to populate the user's display name.
2. **Authorized Requests:** Flutter attaches the Supabase JWT to the `Authorization` header on every request to the backend:
   ```http
   Authorization: Bearer <supabase_access_token>
   ```
3. **JWT Verification in Django:** Django's `SupabaseJWTAuthentication` validates the JWT signature using `SUPABASE_JWT_SECRET`. It automatically extracts the Supabase UUID and creates or retrieves the matching `User` row in PostgreSQL.

---

## 3. Project Setup & Prerequisites

Ensure the following tools are installed on your workstation:
1. **Flutter SDK (3.x or higher) & Android Studio:** With Android SDK tools and Android Emulator configured.
2. **Docker Desktop:** Required to host PostgreSQL/PostGIS and the Django backend containers.
3. **Supabase Account:** Free tier project for Auth and Storage.
4. **Mapbox Account:** Free tier public access token for vector map rendering.

Clone the repository:
```bash
git clone https://github.com/NaesCode/paws_and_found.git
cd paws_and_found
```

---

## 4. Backend & Database Initialization

The backend runs entirely in Docker. No local installation of PostgreSQL or GDAL is required.

1. **Create Backend Environment Variables:**
   ```bash
   cd backend
   cp .env.example .env
   ```
   Fill in your Supabase configuration (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`) and a secure `SECRET_KEY`.

2. **Start the Stack:**
   From the repository root (where `docker-compose.yml` resides):
   ```bash
   docker compose up -d
   ```
   This spins up:
   * `paws_db` (Postgres + PostGIS on port `5432`)
   * `paws_backend` (Django API server on port `8000`)

3. **Apply Migrations:**
   ```bash
   docker compose exec backend python manage.py migrate
   ```

4. **Create a Superuser (Admin Dashboard):**
   ```bash
   docker compose exec backend python manage.py createsuperuser
   ```
   Visit `http://localhost:8000/admin` to confirm the backend is running.

---

## 5. Mobile App Setup (Flutter)

1. Navigate to the mobile app directory:
   ```bash
   cd mobile_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on an Android Emulator or connected physical device:
   ```bash
   flutter run
   ```

> [!NOTE]
> **Android Emulator Networking:**
> The Android emulator connects to your computer's `localhost` via the special IP **`10.0.2.2`**. Therefore, the Django API endpoint from the emulator is `http://10.0.2.2:8000/api/`. On a physical device, use your machine's local Wi-Fi IP address (e.g. `192.168.1.x`).

---

## 6. Geospatial Development (PostGIS & GeoDjango)

All coordinates are stored natively using PostGIS spatial points (`PointField(srid=4326)`).

* **Never** fetch all coordinates and filter them on the client side in Dart.
* Geospatial queries must use GeoDjango's spatial lookups (e.g. `distance_lte` / `dwithin`) so the database utilizes spatial R-Tree indexing:
  ```python
  from django.contrib.gis.geos import Point
  from django.contrib.gis.measure import D
  from core.models import Report

  # Finding reports within 5km of a given coordinate
  user_location = Point(longitude, latitude, srid=4326)
  nearby_reports = Report.objects.filter(location__distance_lte=(user_location, D(m=5000)))
  ```

---

## 7. Security Guidelines

1. **Keep Secrets Out of Client Code:** Never embed the Supabase `service_role` key, database passwords, or JWT secrets in the Flutter app. Only the `publishableKey` (anon key) belongs in the client.
2. **Authenticated Endpoints:** All non-public Django API endpoints must require `IsAuthenticated` permission and resolve the authenticated user through the Supabase JWT.
3. **Private Storage Buckets:** The `animal-photos` storage bucket must remain private. Images are uploaded via the backend or signed URLs.

---

## 8. Branching & Commit Conventions

To avoid merge conflicts, nobody pushes directly to `main`. Always create a branch:

| Branch Prefix | Usage | Example |
| --- | --- | --- |
| `feature/` | Developing new core components | `feature/auth-tray-validation` |
| `bugfix/` | Resolving bugs or crashes | `bugfix/jwt-decode-error` |
| `ui/` | Frontend layout and styling tweaks | `ui/login-segmented-control` |
| `docs/` | Updating documentation | `docs/update-architecture` |

### Commit Message Standards
Commits must follow Conventional Commits:
* `feat: add email format validation to auth tray`
* `fix: correct emulator api host url`
* `chore: update dependencies in pubspec.yaml`
* `docs: update system architecture and readme`

---

## 9. Common Commands Reference

| Action | Command |
| --- | --- |
| Start backend & database | `docker compose up -d` |
| Stop backend & database | `docker compose down` |
| View backend logs | `docker compose logs -f backend` |
| Run Django migrations | `docker compose exec backend python manage.py migrate` |
| Make new migrations | `docker compose exec backend python manage.py makemigrations` |
| Fetch Flutter packages | `flutter pub get` (inside `mobile_app/`) |
| Run Flutter mobile client | `flutter run` (inside `mobile_app/`) |
| Analyze Flutter code | `flutter analyze` (inside `mobile_app/`) |

---

## 10. Frontend Architecture Guide

The `mobile_app/` codebase strictly follows **Feature-Driven Clean Architecture** and **Atomic Design**.

* **`core/`**: App-wide global utilities, theme (`app_colors.dart`), routing, and network clients.
* **`shared/`**: Reusable UI components categorized by Atomic Design (`atoms/`, `molecules/`, `organisms/`, `templates/`). No business logic belongs in shared components.
* **`features/`**: Domain modules (`auth/`, `map/`, `report/`, `feed/`, etc.) structured with `domain/`, `data/`, and `presentation/` layers.

For complete rules on widget placement and component design, refer to the [Frontend Architecture Guide (FRONT_ARCH.md)](./mobile_app/FRONT_ARCH.md).
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
