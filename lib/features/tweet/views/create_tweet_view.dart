import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
// ignore: unused_import
import 'package:carousel_slider/carousel_controller.dart'
    as carousel_controller;
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
  //void onPickImages() async {
  // try {
  //  final pickedImages = await pickImages();
  //  if (pickedImages != null) {
  //   setState(() {
  //     images = pickedImages;
  //  });
  // }
  // } catch (e) {
  //  showSnackBar(context, 'Failed to pick images: $e');
  // }
  // }

  @override
  Widget build(BuildContext context) {
    //final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isLoading = ref.watch(tweetControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close, size: 30),
        ),
        actions: [
          RoundedSmallButton(
            onTap: shareTweet,
            label: 'Tweet',
            backgroundColor: Pallete.blueColor,
            textColor: Pallete.whiteColor,
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0), // Add padding to move it right
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(currentUser.profilePic),
                                radius: 25,
                              ),
                            ),
                            const SizedBox(width: 35),
                            Expanded(
                              child: TextField(
                                controller: tweetTextController,
                                style: const TextStyle(
                                  fontSize: 19,
                                  color: Pallete.whiteColor,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "What's happening?",
                                  hintStyle: TextStyle(
                                    color: Pallete.greyColor,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                              ),
                            ),
                          ],
                        ),
                        if (images.isNotEmpty)
                          carousel_slider.CarouselSlider(
                            items: images.map((file) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Image.file(file),
                              );
                            }).toList(),
                            options: carousel_slider.CarouselOptions(
                                height: 400, enableInfiniteScroll: false),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Pallete.greyColor,
              width: 0.3,
            ),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(left: 15, right: 15),
              child: GestureDetector(
                onTap: onPickImages,
                child: SvgPicture.asset(AssetsConstants.galleryIcon),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(left: 15, right: 15),
              child: SvgPicture.asset(AssetsConstants.gifIcon),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(left: 15, right: 15),
              child: SvgPicture.asset(AssetsConstants.emojiIcon),
            ),
          ],
        ),
      ),
    );
  }
}
