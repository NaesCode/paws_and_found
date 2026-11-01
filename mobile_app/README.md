# Paws and Found - Mobile Application

Welcome to the frontend repository for **Paws and Found**. This Flutter application follows a strictly defined **Feature-Driven Architecture** combined with **Clean Architecture** principles, and utilizes **Atomic Design** for all shared UI components. 

The purpose of this document is to ensure that all frontend developers have a unified understanding of where files belong and how the system scales.

---

## Architecture Overview

The `lib/` directory is split into three main pillars:
1. **`core/`**: App-wide configurations and setup.
2. **`shared/`**: Global UI components built using Atomic Design.
3. **`features/`**: Independent, domain-specific modules containing the actual app logic and screens.

```text
lib/
├── core/
├── shared/
└── features/
```

---

## 1. Core (`lib/core/`)

This directory houses the foundation of the application. Code here is **global** and is not tied to any specific UI feature.

*   **`constants/`**: Global constants, such as API keys, environment variables, layout spacing defaults, or asset paths.
*   **`theme/`**: Global styling configuration (colors, text themes, light/dark mode setup).
*   **`network/`**: Base API clients (like the Supabase client wrapper), interceptors, and error handlers.
*   **`services/`**: Wrappers for external device integrations that are used across multiple features (e.g., GPS location services, push notification handlers).
*   **`routes/`**: Centralized application routing logic.
*   **`utils/`**: Helper functions and extensions (e.g., date formatters, string validators).

**Rule of Thumb:** If a utility or service is only used by one feature, it belongs in that feature's folder, *not* in `core/`.

---

## 2. Shared / Atomic Design (`lib/shared/`)

To maximize reusability, all UI components that appear in more than one feature are placed here, structured according to Atomic Design methodology.

*   **`atoms/`**: The most basic UI elements. They cannot be broken down further without losing their meaning. 
    *   *Examples:* Custom buttons (`PawButton`), typography, icons, or color swatches.
*   **`molecules/`**: Combinations of atoms working together as a simple functional unit.
    *   *Examples:* A search bar (input atom + icon atom), or a form field with a label.
*   **`organisms/`**: Complex, distinct sections of an interface made up of molecules and/or atoms.
    *   *Examples:* The main bottom navigation bar, a map detail modal, or an animal report card used in feeds.
*   **`templates/`**: Generic screen layouts or wrappers that dictate structure but not content.
    *   *Examples:* A `BaseScaffold` with a predefined safe area and app bar.

**Rule of Thumb:** Never put business logic (like API calls) inside these components. They should rely purely on properties passed down to them.

---

## 3. Features (`lib/features/`)

The bulk of the application lives here. We use a **Feature-First** approach. Every major section of the app (e.g., `auth`, `map`, `feed`) has its own folder. 

Inside *each* feature, we follow Clean Architecture, meaning the feature is split into three distinct layers:

### The Layers within a Feature

```text
features/auth/
├── data/
├── domain/
└── presentation/
```

1. **`domain/` (The Business Logic)**
    *   **What goes here:** The pure logic of the feature.
    *   `entities/`: Plain Dart classes representing the data (e.g., `User` class).
    *   `repositories/`: Abstract classes (interfaces) that define what data operations are possible, without implementing *how* they happen.
    *   `usecases/`: Specific actions the app can take (e.g., `LoginUserUseCase`).

2. **`data/` (The External Connections)**
    *   **What goes here:** How the app communicates with the outside world (Supabase, local storage).
    *   `datasources/`: Classes that actually perform the API calls or database queries.
    *   `models/`: Data classes with `fromJson` and `toJson` methods to parse external data, which then extend the `domain/entities`.
    *   `repositories/`: The actual implementations of the interfaces defined in the `domain` layer.

3. **`presentation/` (The UI)**
    *   **What goes here:** What the user sees and interacts with.
    *   `pages/`: Full screen views for this feature (e.g., `LoginPage.dart`).
    *   `widgets/`: UI components that are *only* used within this specific feature. (If a widget is used in multiple features, move it to `lib/shared/`).
    *   `providers/`: State management files (e.g., BLoCs, Cubits, or Riverpod providers).

### Current Features

*   **`auth/`**: Login, registration, and session state.
*   **`dashboard/`**: The central routing hub and primary navigation shell.
*   **`map/`**: Community map interface and location filtering.
*   **`feed/`**: Chronological community activity feeds, interactive comments modal, and dedicated Pet Owner Sightings Log dashboard.
*   **`report/`**: Camera capturing with real-time in-camera AI visual pre-matching (Google Lens-style), automatic missing pet linking (`linked_report_id`), and submitting new animal sightings.
*   **`recovery/`**: AI matching engine reviews and the secure handover process.
*   **`profile/`**: User settings and historical post management.
*   **`notifications/`**: Background alerts and message tracking.

---

## 4. Development & QA Test Accounts

For running the app locally or QA testing frontend flows without registering new email addresses or verifying inboxes, three pre-seeded test accounts exist on Supabase Auth:

| Role / Persona | Email | Password | Profile State | Primary QA Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Pet Owner**<br>(Alex Rivera) | `petowner.test@pawsandfound.com` | `PawsTest2026!` | **Complete** (Phone & Address set) | Register pets, report lost pets, view pet details |
| **Stray Finder**<br>(Sam Cruz) | `strayfinder.test@pawsandfound.com` | `PawsTest2026!` | **Complete** (Phone & Address set) | Report stray sightings, add map pins, test matches & feed |
| **New User**<br>(Jordan Lee) | `newuser.onboarding@pawsandfound.com` | `PawsTest2026!` | **Incomplete** (No phone/address) | Test initial onboarding and profile setup flow |

> [!TIP]
> * **Instant Login:** All test accounts have `email_confirm: true` in Supabase Auth, bypassing email confirmation checks.
> * **First-Time Detection:** In the app, `checkIsFirstTimeUser` checks if phone or address is empty. Logging in as `newuser.onboarding@pawsandfound.com` routes you directly to the profile setup screen, whereas the other two jump straight into the main app feed and map.

---

## Feature Guides & Testing

*   **[Community Animal Map Testing Guide](MAP_TESTING_GUIDE.md)**: Comprehensive architectural overview, OpenStreetMap tile details, interactive QA checklist, and test commands for the interactive map subsystem.
*   **[Thread Linking & Sightings Dashboard Guide](THREAD_LINKING_README.md)**: Architectural overview of in-camera real-time AI visual candidate scanning, `linked_report_id` database relationships, deep linking, and the dual-tab Sightings Log dashboard.
*   **[Sightings Dashboard Proposal & Architecture Spec](SIGHTINGS_DASHBOARD_PROPOSAL.md)**: Product proposal and technical specification for connecting spotted animal reports to missing pet owners.

