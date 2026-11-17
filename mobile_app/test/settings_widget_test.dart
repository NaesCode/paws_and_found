import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/constants/app_legal_constants.dart';
import 'package:paws_and_found/features/profile/presentation/widgets/profile_header.dart';
import 'package:paws_and_found/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:paws_and_found/features/settings/data/models/user_settings_model.dart';
import 'package:paws_and_found/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:paws_and_found/features/settings/domain/entities/user_settings.dart';
import 'package:paws_and_found/features/settings/presentation/pages/settings_page.dart';
import 'package:paws_and_found/features/settings/presentation/providers/settings_controller.dart';
import 'package:paws_and_found/features/settings/presentation/widgets/settings_legal_card.dart';
import 'package:paws_and_found/features/settings/presentation/widgets/settings_sound_card.dart';
import 'package:paws_and_found/shared/atoms/paw_switch.dart';
import 'package:paws_and_found/shared/atoms/settings_section_header.dart';
import 'package:paws_and_found/shared/molecules/settings_switch_tile.dart';
import 'package:paws_and_found/shared/molecules/settings_tile.dart';
import 'package:paws_and_found/shared/molecules/sound_type_selector_tile.dart';
import 'package:paws_and_found/shared/organisms/legal_document_dialog.dart';

void main() {
  group('Settings Atomic Design Components', () {
    testWidgets('PawSwitch atom renders and triggers onChanged', (
      tester,
    ) async {
      bool switchValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PawSwitch(
                  value: switchValue,
                  onChanged: (val) {
                    setState(() => switchValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(PawSwitch), findsOneWidget);
      expect(switchValue, isFalse);

      await tester.tap(find.byType(PawSwitch));
      await tester.pumpAndSettle();

      expect(switchValue, isTrue);
    });

    testWidgets('SettingsSectionHeader atom renders title in uppercase', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsSectionHeader(title: 'Alert Preferences'),
          ),
        ),
      );

      expect(find.text('ALERT PREFERENCES'), findsOneWidget);
    });

    testWidgets(
      'SettingsSwitchTile molecule renders title, subtitle, and responds to switch',
      (tester) async {
        bool isEnabled = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SettingsSwitchTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Notification Sounds',
                    subtitle: 'Play sound effects',
                    value: isEnabled,
                    onChanged: (val) {
                      setState(() => isEnabled = val);
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Notification Sounds'), findsOneWidget);
        expect(find.text('Play sound effects'), findsOneWidget);
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

        await tester.tap(find.byType(PawSwitch));
        await tester.pumpAndSettle();

        expect(isEnabled, isFalse);
      },
    );

    testWidgets(
      'SettingsTile molecule renders title, subtitle, and triggers onTap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsTile(
                icon: Icons.article_outlined,
                title: 'Terms of Service',
                subtitle: 'Read community guidelines',
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Read community guidelines'), findsOneWidget);
        expect(find.byIcon(Icons.article_outlined), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

        await tester.tap(find.text('Terms of Service'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'SoundTypeSelectorTile molecule opens bottom sheet and changes sound type',
      (tester) async {
        NotificationSoundType selectedType = NotificationSoundType.cat;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SoundTypeSelectorTile(
                    selectedType: selectedType,
                    onTypeChanged: (newType) {
                      setState(() => selectedType = newType);
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Notification Sound Type'), findsOneWidget);
        expect(find.text('Cat Sound'), findsOneWidget);

        // Tap tile to open bottom sheet
        await tester.tap(find.byType(SoundTypeSelectorTile));
        await tester.pumpAndSettle();

        // Bottom sheet options
        expect(find.text('Select Notification Sound'), findsOneWidget);
        expect(find.text('Cat Sound'), findsWidgets);
        expect(find.text('Dog Sound'), findsOneWidget);
        expect(find.text('Bird Sound'), findsOneWidget);

        // Tap Dog Sound
        await tester.tap(find.text('Dog Sound'));
        await tester.pumpAndSettle();

        expect(selectedType, NotificationSoundType.dog);
      },
    );

    testWidgets(
      'LegalDocumentDialog renders Terms of Service content and dismisses',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        LegalDocumentDialog.showTermsOfService(context),
                    child: const Text('Open Terms'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Terms'));
        await tester.pumpAndSettle();

        expect(
          find.text(AppLegalConstants.termsOfServiceTitle),
          findsOneWidget,
        );
        expect(
          find.text('Last Updated: ${AppLegalConstants.lastUpdated}'),
          findsOneWidget,
        );
        expect(find.text('1. Acceptance of Terms'), findsOneWidget);

        // Tap I Understand button to close
        await tester.tap(find.text('I Understand'));
        await tester.pumpAndSettle();

        expect(find.text(AppLegalConstants.termsOfServiceTitle), findsNothing);
      },
    );

    testWidgets(
      'LegalDocumentDialog renders Privacy Policy content and dismisses via close button',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        LegalDocumentDialog.showPrivacyPolicy(context),
                    child: const Text('Open Privacy'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Privacy'));
        await tester.pumpAndSettle();

        expect(find.text(AppLegalConstants.privacyPolicyTitle), findsOneWidget);
        expect(find.text('1. Information We Collect'), findsOneWidget);

        // Tap top close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text(AppLegalConstants.privacyPolicyTitle), findsNothing);
      },
    );
  });

  group('Settings Clean Architecture Controller & Repository', () {
    test(
      'SettingsController loads default and updates notification sounds',
      () async {
        final fakeDataSource = _MockSettingsDataSource();
        final repo = SettingsRepositoryImpl(dataSource: fakeDataSource);
        final controller = SettingsController(repository: repo);

        await controller.loadSettings();
        expect(controller.notificationSoundsEnabled, isTrue);
        expect(controller.soundType, NotificationSoundType.cat);

        // Toggle sounds off
        await controller.setNotificationSounds(false);
        expect(controller.notificationSoundsEnabled, isFalse);

        // Toggle sound type to bird
        await controller.setSoundType(NotificationSoundType.bird);
        expect(controller.soundType, NotificationSoundType.bird);
      },
    );
  });

  group('SettingsPage Full Screen Integration', () {
    testWidgets('SettingsPage renders sections and opens legal popups', (
      tester,
    ) async {
      final fakeDataSource = _MockSettingsDataSource();
      final repo = SettingsRepositoryImpl(dataSource: fakeDataSource);
      final controller = SettingsController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(home: SettingsPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Verify Headers
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ALERT PREFERENCES'), findsOneWidget);
      expect(find.text('LEGAL & POLICIES'), findsOneWidget);

      // Verify Sound & Legal Cards
      expect(find.byType(SettingsSoundCard), findsOneWidget);
      expect(find.byType(SettingsLegalCard), findsOneWidget);
      expect(find.text('Paws and Found · v1.0.0'), findsOneWidget);

      // Tap Terms of Service row
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(
        find.text('Terms of Service'),
        findsNWidgets(2),
      ); // Card row + Dialog title
      expect(find.text('I Understand'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      // Tap Privacy Policy row
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(
        find.text('Privacy Policy'),
        findsNWidgets(2),
      ); // Card row + Dialog title
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'ProfileHeader displays Settings in overflow menu and triggers onSettingsPressed',
      (tester) async {
        bool settingsTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProfileHeader(
                onSettingsPressed: () => settingsTapped = true,
              ),
              body: const Center(child: Text('Profile Content')),
            ),
          ),
        );

        // Tap 3-dot overflow menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify 'Settings' item is present
        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

        // Tap 'Settings'
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        expect(settingsTapped, isTrue);
      },
    );
  });
}

class _MockSettingsDataSource implements SettingsLocalDataSource {
  UserSettings _data = const UserSettings();

  @override
  Future<UserSettingsModel> getSettings() async {
    return UserSettingsModel.fromEntity(_data);
  }

  @override
  Future<void> saveSettings(UserSettingsModel model) async {
    _data = model;
  }
}
