# Application Routing (`go_router`)

This project uses `go_router` for all navigation and screen routing. It is centralized here in `app_router.dart` to support nested shell routes (like persistent bottom navigation bars) and deep linking.

## How to Navigate

Do **NOT** use `Navigator.push` or `Navigator.pop`. Instead, use the `go_router` extensions on the `BuildContext`.

### Go to a new screen:
Use `context.go()` to replace the current URL/Stack. This is best for top-level navigation (like jumping from a Feed tab to a Profile tab).
```dart
// Navigates directly to the login screen
context.go('/login');
```

### Push a screen on top:
Use `context.push()` if you want to stack a screen on top of the current one, keeping a back button.
```dart
context.push('/pet-details/123');
```

### Go Back:
Use `context.pop()` to dismiss dialogs, bottom sheets, or screens that were pushed.
```dart
context.pop();
```

## Adding a New Route

When you create a new page in a feature (e.g. `lib/features/settings/presentation/pages/settings_page.dart`), you must register it here in `app_router.dart`.

```dart
GoRoute(
  path: '/settings',
  name: 'settings',
  builder: (context, state) => const SettingsPage(),
),
```

*Note: The Dashboard shell route handles the main bottom navigation tabs. Tab pages should be added as children of the ShellRoute, not as top-level routes.*
