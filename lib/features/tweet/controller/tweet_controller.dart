// Update the shareTweet methods to handle health points
void _updateUserHealthPoints(String category, String uid) async {
  final userAPI = _ref.read(userAPIProvider);
  final userData = await userAPI.getUserData(uid);
  final user = UserModel.fromMap(userData.data);
  
  // Update health points based on tweet category
  final newPoints = user.healthPoints + (category.toLowerCase() == 'healthy' ? 1 : -1);
  
  // Ensure points don't go below 0
  final updatedPoints = newPoints < 0 ? 0 : newPoints;
  
  final updatedUser = user.copyWith(healthPoints: updatedPoints);
  await userAPI.updateUserData(updatedUser);
}

// In both _shareImageTweet and _shareTextTweet methods, after classification:
if (category.toLowerCase() == 'healthy' || category.toLowerCase() == 'unhealthy') {
  await _updateUserHealthPoints(category, user.uid);
}