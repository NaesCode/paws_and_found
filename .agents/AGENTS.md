# Project Rules and Instructions

## 1. Architecture & Design
*   When developing the frontend or making architecture decisions, **always refer to the `mobile_app/README.md` file**. It acts as the primary source of truth for the project's structure.
*   Ensure that all new Flutter components strictly adhere to the **Atomic Design** structure (inside `lib/shared/`) and **Clean Architecture** rules (inside `lib/features/`).

## 2. Asset Management (Images, SVGs, Fonts)
*   **Centralized Assets Folder**: Always place new images, SVGs, or fonts inside the respective subdirectories of `mobile_app/assets/` (e.g., `assets/images/`, `assets/svgs/`).
*   **No Hardcoded Paths**: When using an asset in a widget, **do not hardcode the string path directly in the UI code** (e.g., avoid `Image.asset('assets/images/logo.png')`).
*   **Use Constants**: Define the asset path as a static constant in a centralized file (e.g., create a `lib/core/constants/app_assets.dart` file) and reference that constant in your UI (e.g., `Image.asset(AppAssets.logo)`).

## 3. UI and Shared Components
*   **Reusable Components**: If a UI component is used in more than one feature, it MUST be placed in `lib/shared/` and categorized correctly into atoms, molecules, organisms, or templates.
*   **Dumb Components**: Shared UI components must rely purely on passed properties and callbacks. They should never execute business logic, make API calls, or be tightly coupled to a specific state manager.

## 4. Feature Development
*   **Layer Separation**: Inside `lib/features/<feature_name>/`, strictly maintain the separation of `presentation` (UI), `domain` (Business Logic), and `data` (External Connections/Repositories).
*   **Core vs Feature**: If a service, utility, or network interceptor is used globally across multiple features, it belongs in `lib/core/`. If it is specific to one feature, it stays within that feature's directory.
