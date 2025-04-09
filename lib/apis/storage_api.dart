import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants/contants.dart';
import 'package:twitter_clone/core/providers.dart';


final storageAPIProvider = Provider((ref){
return StorageAPI(storage: ref.watch(appwriteStorageProvider));}
);


class StorageAPI {
  final Storage _storage;
  StorageAPI({required storage}) : _storage = storage;
  Future<List<String>> uploadImage(List<File> files) async {
    List<String> imageLinks = [];

    for (final file in files) {
     // final file = File(image.path);
     // final fileName = file.path.split('/').last;
      final uploadedImage = await _storage.createFile(
        bucketId: AppwriteConstants.imagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: file.path,
        ),
      );
      imageLinks.add(
        AppwriteConstants.imageURL(uploadedImage.$id),
      );
    }
    return imageLinks;
  }
}
