import '../models/admin_post_item.dart';
import '../models/admin_user_item.dart';

/// Static wireframe fixtures faithfully mirroring SDD Screens 09 & 10.
class AdminStaticData {
  AdminStaticData._();

  /// Screen 09 — ADMIN · USERS static list
  static const List<AdminUserItem> users = [
    AdminUserItem(
      id: 'user-01',
      name: 'Maria Santos',
      emailMasked: 'm..',
      reputation: 8,
      status: 'Active',
    ),
    AdminUserItem(
      id: 'user-02',
      name: 'Jake Rivera',
      emailMasked: 'j..',
      reputation: 3,
      status: 'Active',
    ),
    AdminUserItem(
      id: 'user-03',
      name: 'Anna Cruz',
      emailMasked: 'a..',
      reputation: 0,
      status: 'Suspended',
    ),
    AdminUserItem(
      id: 'user-04',
      name: 'Ben Torres',
      emailMasked: 'b..',
      reputation: 12,
      status: 'Active',
    ),
  ];

  /// Screen 10 — ADMIN · POSTS static list
  static const List<AdminPostItem> posts = [
    AdminPostItem(
      id: '#041',
      title: 'Tabby',
      subtitle: 'Cat',
      status: 'missing',
      dateFormatted: 'Sep 20',
      username: 'maria_s',
      isFlagged: false,
    ),
    AdminPostItem(
      id: '#042',
      title: 'Golden',
      subtitle: 'Retriever',
      status: 'stray',
      dateFormatted: 'Sep 20',
      username: 'jake_r',
      isFlagged: true,
    ),
    AdminPostItem(
      id: '#043',
      title: 'Beagle',
      subtitle: null,
      status: 'found',
      dateFormatted: 'Sep 21',
      username: 'ben_t',
      isFlagged: false,
    ),
    AdminPostItem(
      id: '#044',
      title: 'Mixed',
      subtitle: 'Dog',
      status: 'missing',
      dateFormatted: 'Sep 21',
      username: 'anna_c',
      isFlagged: false,
    ),
  ];
}

