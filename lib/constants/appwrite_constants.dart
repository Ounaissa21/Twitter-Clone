class AppwriteConstants {
  static const String databaseId = '682e435d003a1afad98c';
  static const String projectId = '682e3f8f000d76bff0a2';
  static const String endPoint =
      'http://192.168.137.1/v1'; //192.168.137.1 / 192.168.241.2

  static const String usersCollection = '682e43cb001329e8eddc';
  static const String tweetsCollection = '682e43ee00001dd447c2';
  static const String notificationsCollection = '682e44030034680ee2aa';

  static const String imagesBucket = '682e4425002891028939';

  static String imageURL(String imageId) =>
      '$endPoint/storage/buckets/$imagesBucket/files/$imageId/view?project=$projectId&mode=admin';
}
