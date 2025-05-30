import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitter_clone/common/common.dart';
import 'package:twitter_clone/constants/assets_constants.dart';
import 'package:twitter_clone/core/utils.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/theme/pallete.dart';

class CreateTweetScreen extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const CreateTweetScreen(),
      );
  const CreateTweetScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateTweetScreenState();
}

class _CreateTweetScreenState extends ConsumerState<CreateTweetScreen> {
  final tweetTextController = TextEditingController();
  List<File> images = [];
  bool get canTweet => tweetTextController.text.trim().isNotEmpty || images.isNotEmpty;

  @override
  void dispose() {
    super.dispose();
    tweetTextController.dispose();
  }

  void shareTweet() {
    ref.read(tweetControllerProvider.notifier).shareTweet(
          text: tweetTextController.text,
          images: images,
          context: context,
          repliedTo: '',
          repliedToUserId: '',
        );
    Navigator.pop(context);
  }

  void onPickImages() async {
    images = await pickImages();
    setState(() {});
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(tweetControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: canTweet ? shareTweet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canTweet ? Colors.blue : Colors.grey[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 0,
              ),
              child: const Text(
                'Tweet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Loader()
          : Builder(
              builder: (context) {
                final currentUser = ref.watch(currentUserDetailsProvider).value;
                if (currentUser == null) {
                  return const Loader();
                }

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(currentUser.profilePic),
                                      radius: 25,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: tweetTextController,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: "What's happening?",
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 20,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            maxLines: null,
                                            onChanged: (text) {
                                              setState(() {});
                                            },
                                          ),
                                          if (images.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            if (images.length == 1)
                                              Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: Image.file(
                                                      images[0],
                                                      width: double.infinity,
                                                      height: 300,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () => removeImage(0),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              carousel_slider.CarouselSlider(
                                                items: images.asMap().entries.map((entry) {
                                                  int index = entry.key;
                                                  File file = entry.value;
                                                  return Stack(
                                                    children: [
                                                      Container(
                                                        width: MediaQuery.of(context).size.width,
                                                        margin: const EdgeInsets.symmetric(horizontal: 5),
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(16),
                                                          child: Image.file(
                                                            file,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 13,
                                                        child: GestureDetector(
                                                          onTap: () => removeImage(index),
                                                          child: Container(
                                                            padding: const EdgeInsets.all(4),
                                                            decoration: const BoxDecoration(
                                                              color: Colors.black54,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color: Colors.white,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                                options: carousel_slider.CarouselOptions(
                                                  height: 300,
                                                  enableInfiniteScroll: false,
                                                  viewportFraction: 0.9,
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}