class AppwriteConstants {
  static const String databaseId = '67e4a2bc0013e22ec67a';
  static const String projectId = '67e49ec2001e8b70a5b8';
  static const String endPoint =
      'http://192.168.137.1/v1'; //192.168.137.1 / 192.168.241.2

  static const String usersCollection = '67e81350002ad32b62f6';
  static const String tweetsCollection = '67ebe82300160d1a857e';
  static const String notificationsCollection = '67ee7f7100324692558e';

  static const String imagesBucket = '67ec03420030b2e3bd66';

  static String imageURL(String imageId) =>
      '$endPoint/storage/buckets/$imagesBucket/files/$imageId/view?project=$projectId&mode=admin';
}
