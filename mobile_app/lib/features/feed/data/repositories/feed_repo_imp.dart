import "../datasources/feed_mock_data.dart";
import "../models/feed_post_model.dart";

//connect the posts to each person

class FeedRepoImp {
  List<PetPostModel> _joinAndMapReports(List<Map<String, dynamic>> rawPostList)
  {
    return rawPostList.map((postRaw) {
      final Map<String, dynamic> userRaw = mockUsers.firstWhere(
        (user) => user['id'] == postRaw['user_id'],
        orElse: () => <String,dynamic>{}, //aron dli mu crash if walay makita nga same user
      );

      return PetPostModel.fromJoinedData(
        postRaw,
        userRaw.isEmpty ? null : userRaw,
      );
    }).toList();
  }

  //getting the general reports
  Future <List<PetPostModel>> getGeneralReports() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _joinAndMapReports(mockPosts);
  }

  Future <List<PetPostModel>> getPersonalReports(String currentUserId) async{
    await Future.delayed(const Duration(milliseconds: 500));

    final List<Map<String, dynamic>> userSpecificPosts = mockPosts
      .where((post) => post['user_id'] == currentUserId)
      .toList();

    return _joinAndMapReports(userSpecificPosts);
  }
}
