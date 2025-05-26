import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:twitter_clone/features/tweet/views/hashtag_view.dart';
// Make sure that the HashtagView class exists in the imported file and is exported properly.
import 'package:twitter_clone/theme/pallete.dart';

class HashtagText extends StatelessWidget {
  final String text;
  const HashtagText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    List<TextSpan> textSpans = [];
    text.split(' ').forEach(
      (element) {
        if (element.startsWith('#')) {
          // Style hashtags
          textSpans.add(TextSpan(
            text: '$element ',
            style: const TextStyle(
              color: Pallete.blueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(context, HashtagView.route(element));
              },
          ));
        } else if (element.startsWith("www.") ||
            element.startsWith("http://") ||
            element.startsWith("https://")) {
          // Style links
          textSpans.add(TextSpan(
            text: '$element ',
            style: const TextStyle(
              color: Pallete.blueColor,
              fontSize: 18,
              // decoration: TextDecoration.underline, // Optional: underline links
            ),
          ));
        } else {
          // Style normal text
          textSpans.add(TextSpan(
            text: '$element ',
            style: const TextStyle(
              fontSize: 18,
            ),
          ));
        }
      },
    );
    return RichText(
      text: TextSpan(
        children: textSpans,
        style:
            DefaultTextStyle.of(context).style, // Ensure consistent text style
      ),
    );
  }
}
