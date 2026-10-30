import '../../data/models/admin_post_item.dart';
import '../../data/models/admin_user_item.dart';

abstract class AdminRepository {
  Future<List<AdminUserItem>> fetchUsers();
  Future<List<AdminPostItem>> fetchPosts();
  Future<void> deletePost(
    String postId, {
    String? reason,
    bool notifyUser = false,
  });
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? message,
  });
  Future<void> warnUserForPost({
    required String postId,
    required String userId,
    required String reason,
    String? message,
  });
}
