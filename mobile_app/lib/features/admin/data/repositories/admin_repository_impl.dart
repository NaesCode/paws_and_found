import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/admin_post_item.dart';
import '../models/admin_user_item.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({AdminRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AdminRemoteDataSourceImpl();

  @override
  Future<List<AdminUserItem>> fetchUsers() {
    return _remoteDataSource.fetchUsers();
  }

  @override
  Future<List<AdminPostItem>> fetchPosts() {
    return _remoteDataSource.fetchPosts();
  }

  @override
  Future<void> deletePost(
    String postId, {
    String? reason,
    bool notifyUser = false,
  }) {
    return _remoteDataSource.deletePost(
      postId,
      reason: reason,
      notifyUser: notifyUser,
    );
  }

  @override
  Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? message,
  }) {
    return _remoteDataSource.updateUserStatus(
      userId: userId,
      status: status,
      message: message,
    );
  }

  @override
  Future<void> warnUserForPost({
    required String postId,
    required String userId,
    required String reason,
    String? message,
  }) {
    return _remoteDataSource.warnUserForPost(
      postId: postId,
      userId: userId,
      reason: reason,
      message: message,
    );
  }
}
