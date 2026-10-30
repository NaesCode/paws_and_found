import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/admin/data/models/admin_post_item.dart';
import 'package:paws_and_found/features/admin/data/models/admin_user_item.dart';
import 'package:paws_and_found/features/admin/domain/repositories/admin_repository.dart';
import 'package:paws_and_found/features/admin/presentation/pages/admin_page.dart';
import 'package:paws_and_found/features/admin/presentation/pages/admin_posts_page.dart';
import 'package:paws_and_found/features/admin/presentation/pages/admin_users_page.dart';
import 'package:paws_and_found/features/admin/presentation/widgets/admin_header.dart';
import 'package:paws_and_found/features/admin/presentation/widgets/admin_post_status_pill.dart';
import 'package:paws_and_found/features/admin/presentation/widgets/admin_user_status_pill.dart';

class FakeAdminRepository implements AdminRepository {
  final List<AdminUserItem> users;
  final List<AdminPostItem> posts;
  String? deletedPostId;
  String? deletedReason;
  bool? deletedNotifyUser;
  String? updatedUserId;
  String? updatedStatus;
  String? updatedMessage;
  String? warnedPostId;
  String? warnedUserId;
  String? warnedReason;
  String? warnedMessage;

  FakeAdminRepository({
    this.users = const [],
    this.posts = const [],
  });

  @override
  Future<List<AdminUserItem>> fetchUsers() async => users;

  @override
  Future<List<AdminPostItem>> fetchPosts() async => posts;

  Map<String, dynamic>? deletedPostData;
  Map<String, dynamic>? warnedPostData;

  @override
  Future<void> deletePost(
    String postId, {
    String? reason,
    bool notifyUser = false,
    Map<String, dynamic>? postData,
  }) async {
    deletedPostId = postId;
    deletedReason = reason;
    deletedNotifyUser = notifyUser;
    deletedPostData = postData;
  }

  @override
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? message,
  }) async {
    updatedUserId = userId;
    updatedStatus = status;
    updatedMessage = message;
  }

  @override
  Future<void> warnUserForPost({
    required String postId,
    required String userId,
    required String reason,
    String? message,
    Map<String, dynamic>? postData,
  }) async {
    warnedPostId = postId;
    warnedUserId = userId;
    warnedReason = reason;
    warnedMessage = message;
    warnedPostData = postData;
  }
}

void main() {
  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Admin Functions & Static UI Tests (SDD Screens 09 & 10)', () {
    testWidgets('AdminHeader renders title dropdown selector and circular dropdown button with Log Out', (tester) async {
      bool loggedOut = false;
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminHeader(
              title: 'User Management',
              selectedTabIndex: selectedTab,
              onTabChanged: (index) => selectedTab = index,
              onLogout: () => loggedOut = true,
            ),
          ),
        ),
      );

      // Verify 'A' badge and title
      expect(find.text('A'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);

      // Verify circular dropdown button beside ADMIN rectangle
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      // Tap circular button to open dropdown menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify 'Log Out' item is visible
      expect(find.text('Log Out'), findsOneWidget);

      // Tap 'Log Out'
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });

    testWidgets('AdminUserStatusPill displays Active, Warning, and Suspended correctly without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdminUserStatusPill(status: 'Active'),
                AdminUserStatusPill(status: 'Warning'),
                AdminUserStatusPill(status: 'Suspension'),
                AdminUserStatusPill(status: 'Suspended'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Suspension'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
    });

    testWidgets('AdminPostStatusPill renders Missing, Stray, Found badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdminPostStatusPill(status: 'missing'),
                AdminPostStatusPill(status: 'stray'),
                AdminPostStatusPill(status: 'found'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Missing'), findsOneWidget);
      expect(find.text('Stray'), findsOneWidget);
      expect(find.text('Found'), findsOneWidget);
    });

    testWidgets('Screen 09 — AdminUsersPage renders, searches, and handles actions', (tester) async {
      setMobileScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminUsersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Columns
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('Search users...'), findsOneWidget);
      expect(find.text('NAME'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);

      // Verify Wireframe Users
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Jake Rivera'), findsOneWidget);

      // Test Search functionality
      await tester.enterText(find.byType(TextField), 'Jake');
      await tester.pumpAndSettle();

      expect(find.text('Jake Rivera'), findsOneWidget);
      expect(find.text('Maria Santos'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Maria Santos'), findsOneWidget);

      // Tap on Export button
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('User export triggered for CSV'), findsOneWidget);

      // Wait for SnackBar to dismiss before next tap
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap on + Add User button
      await tester.tap(find.text('+ Add User'));
      await tester.pumpAndSettle();
      expect(find.text('Add user modal triggered for New User'), findsOneWidget);
    });

    testWidgets('Screen 10 — AdminPostsPage filters and shows action menu', (tester) async {
      setMobileScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPostsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Initial Posts
      expect(find.text('Post Management'), findsOneWidget);
      expect(find.text('#041'), findsOneWidget);
      expect(find.text('#042'), findsOneWidget);
      expect(find.text('1 flagged'), findsOneWidget);

      // Test Filter chip (first occurrence of 'Stray' is the filter chip)
      await tester.tap(find.text('Stray').first);
      await tester.pumpAndSettle();

      expect(find.text('#042'), findsOneWidget);
      expect(find.text('#041'), findsNothing);

      // Switch back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('#041'), findsOneWidget);

      // Tap on three dots action button for first post
      await tester.tap(find.text('···').first);
      await tester.pumpAndSettle();

      // Verify bottom sheet actions
      expect(find.text('View Full Sighting Details'), findsOneWidget);
      expect(find.text('Send Warning to User'), findsOneWidget);
      expect(find.text('Delete Post from Community'), findsOneWidget);

      // Tap Delete Post action
      await tester.tap(find.text('Delete Post from Community'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Delete Post from Community?'), findsOneWidget);
      await tester.tap(find.text('Delete Post'));
      await tester.pumpAndSettle();
      expect(find.text('Deleted Post: #041'), findsOneWidget);
    });

    testWidgets('Screen 10 — AdminPostsPage with FakeAdminRepository displays live fetched posts and deletes', (tester) async {
      setMobileScreen(tester);

      final fakeRepo = FakeAdminRepository(
        posts: [
          const AdminPostItem(
            id: '#9B2A',
            rawId: '9b2a-uuid-1234',
            title: 'Milo',
            subtitle: 'Husky',
            status: 'missing',
            dateFormatted: 'Oct 28',
            username: 'alice_w',
            isFlagged: true,
          ),
          const AdminPostItem(
            id: '#8C1D',
            rawId: '8c1d-uuid-5678',
            title: 'Siamese',
            subtitle: 'Cat',
            status: 'found',
            dateFormatted: 'Oct 29',
            username: 'carlos_g',
            isFlagged: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPostsPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify live posts rendered
      expect(find.text('#9B2A'), findsOneWidget);
      expect(find.text('Milo'), findsOneWidget);
      expect(find.text('Husky'), findsOneWidget);
      expect(find.text('Oct 28'), findsOneWidget);
      expect(find.text('alice_w'), findsOneWidget);
      expect(find.text('1 flagged'), findsOneWidget);

      // Tap three dots on Milo and delete
      await tester.tap(find.text('···').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Post from Community'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Delete Post from Community?'), findsOneWidget);
      await tester.tap(find.text('Delete Post'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deletedPostId, equals('9b2a-uuid-1234'));
      expect(find.text('#9B2A'), findsNothing);
      expect(find.text('Deleted Post: #9B2A'), findsOneWidget);
    });

    testWidgets('Screen 10 — tapping View Full Sighting Details opens full details modal', (tester) async {
      setMobileScreen(tester);

      final fakeRepo = FakeAdminRepository(
        posts: [
          const AdminPostItem(
            id: '#9B2A',
            rawId: '9b2a-uuid-1234',
            title: 'Milo',
            subtitle: 'Husky',
            status: 'missing',
            dateFormatted: 'Oct 28',
            username: 'alice_w',
            isFlagged: true,
            description: 'Friendly Siberian Husky with a blue collar.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPostsPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Open action menu
      await tester.tap(find.text('···').first);
      await tester.pumpAndSettle();

      // Tap View Full Sighting Details
      await tester.tap(find.text('View Full Sighting Details'));
      await tester.pumpAndSettle();

      // Verify modal contents
      expect(find.text('Post #9B2A'), findsOneWidget);
      expect(find.text('Full Description'), findsOneWidget);
      expect(find.text('Friendly Siberian Husky with a blue collar.'), findsOneWidget);
      expect(find.text('This post was flagged for administrative review.'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Full Description'), findsNothing);
    });

    test('AdminPostItem.fromJson handles Supabase report with joined profile and pet', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        'animal_type': 'Dog',
        'description': 'Friendly dog spotted near market',
        'status': 'stray',
        'created_at': '2026-10-30T10:00:00Z',
        'reporter_id': 'rep-uuid-9999',
        'is_flagged': true,
        'profiles': {
          'name': 'Carlos Gomez',
          'email': 'carlos@example.com',
        },
        'pets': {
          'name': 'Rex',
          'breed': 'German Shepherd',
          'species': 'Dog',
        },
      };

      final post = AdminPostItem.fromJson(json);

      expect(post.id, equals('#A1B2'));
      expect(post.rawId, equals('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'));
      expect(post.title, equals('Rex'));
      expect(post.subtitle, equals('German Shepherd'));
      expect(post.status, equals('stray'));
      expect(post.dateFormatted, equals('Oct 30'));
      expect(post.username, equals('Carlos Gomez'));
      expect(post.isFlagged, isTrue);
    });

    testWidgets('AdminPage shell smoothly toggles between Users and Posts via title dropdown selector', (tester) async {
      setMobileScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Tab 0: Users
      expect(find.text('User Management'), findsOneWidget);

      // Tap title dropdown to switch to Posts
      await tester.tap(find.text('User Management'));
      await tester.pumpAndSettle();

      // Select 'Post Management'
      await tester.tap(find.text('Post Management').last);
      await tester.pumpAndSettle();
      expect(find.text('Post Management'), findsOneWidget);

      // Tap title dropdown to switch back to Users
      await tester.tap(find.text('Post Management'));
      await tester.pumpAndSettle();

      // Select 'User Management'
      await tester.tap(find.text('User Management').last);
      await tester.pumpAndSettle();
      expect(find.text('User Management'), findsOneWidget);
    });

    testWidgets('Screen 09 — AdminUsersPage taps status pill and updates user status with notification message', (tester) async {
      setMobileScreen(tester);

      final fakeRepo = FakeAdminRepository(
        users: [
          const AdminUserItem(
            id: 'user-uuid-1111',
            name: 'Maria Santos',
            emailMasked: 'm..',
            fullEmail: 'maria@example.com',
            status: 'Active',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminUsersPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on status pill 'Active'
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      // Verify update status modal is displayed
      expect(find.text('Update User Status'), findsOneWidget);
      expect(find.text('SELECT STATUS'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Suspension'), findsOneWidget);

      // Select 'Warning' status
      await tester.tap(find.text('Warning'));
      await tester.pumpAndSettle();

      // Verify notification message field auto-fills with warning message
      expect(find.text('Your account has received an administrative warning regarding community guidelines.'), findsOneWidget);

      // Tap Apply Status & Notify User
      await tester.tap(find.text('Apply Status & Notify User'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatedUserId, equals('user-uuid-1111'));
      expect(fakeRepo.updatedStatus, equals('Warning'));
      expect(fakeRepo.updatedMessage, contains('administrative warning'));
      expect(find.text('Status updated to Warning triggered for Maria Santos'), findsOneWidget);
    });

    testWidgets('Screen 10 — tapping Send Warning to User opens modal, selects reason, and dispatches warning notification', (tester) async {
      setMobileScreen(tester);

      final fakeRepo = FakeAdminRepository(
        posts: [
          const AdminPostItem(
            id: '#9B2A',
            rawId: '9b2a-uuid-1234',
            title: 'Milo',
            subtitle: 'Husky',
            status: 'missing',
            dateFormatted: 'Oct 28',
            username: 'alice_w',
            reporterId: 'user-uuid-999',
            isFlagged: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPostsPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Open action menu
      await tester.tap(find.text('···').first);
      await tester.pumpAndSettle();

      // Tap Send Warning to User
      await tester.tap(find.text('Send Warning to User'));
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.text('Send Warning to User'), findsOneWidget);
      expect(find.text('Post #9B2A · Author: alice_w'), findsOneWidget);
      expect(find.text('SELECT REASON FOR WARNING'), findsOneWidget);
      expect(find.text('Community Guidelines Violation'), findsOneWidget);

      // Select 'Community Guidelines Violation'
      await tester.tap(find.text('Community Guidelines Violation'));
      await tester.pumpAndSettle();

      // Verify notification message contains the reason
      expect(find.textContaining('Community Guidelines Violation'), findsWidgets);

      // Submit warning
      await tester.tap(find.text('Send Warning & Update Status'));
      await tester.pumpAndSettle();

      expect(fakeRepo.warnedPostId, equals('9b2a-uuid-1234'));
      expect(fakeRepo.warnedUserId, equals('user-uuid-999'));
      expect(fakeRepo.warnedReason, equals('Community Guidelines Violation'));
      expect(fakeRepo.warnedMessage, contains('Community Guidelines Violation'));
      expect(find.text('Warning sent to: alice_w for Post #9B2A'), findsOneWidget);
    });

    testWidgets('Screen 10 — tapping Delete Post from Community opens confirmation dialog with notify toggle', (tester) async {
      setMobileScreen(tester);

      final fakeRepo = FakeAdminRepository(
        posts: [
          const AdminPostItem(
            id: '#8C1D',
            rawId: '8c1d-uuid-5678',
            title: 'Siamese',
            subtitle: 'Cat',
            status: 'found',
            dateFormatted: 'Oct 29',
            username: 'carlos_g',
            reporterId: 'user-uuid-777',
            isFlagged: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPostsPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Open action menu
      await tester.tap(find.text('···').first);
      await tester.pumpAndSettle();

      // Tap Delete Post
      await tester.tap(find.text('Delete Post from Community'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Post from Community?'), findsOneWidget);
      expect(find.textContaining('permanently delete post'), findsOneWidget);
      expect(find.text('#8C1D'), findsWidgets);
      expect(find.text('Notify author about removal'), findsOneWidget);

      // Toggle notification checkbox off and on
      await tester.tap(find.text('Notify author about removal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notify author about removal'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete Post'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deletedPostId, equals('8c1d-uuid-5678'));
      expect(fakeRepo.deletedNotifyUser, isTrue);
      expect(find.text('#8C1D'), findsNothing);
      expect(find.text('Deleted Post: #8C1D'), findsOneWidget);
    });
  });
}
