import 'package:flutter/foundation.dart';
import 'package:twitter_clone/core/enums/tweet_type_enum.dart';

@immutable
class Tweet {
  final String text;
  final List<String> hashtags;
  final String link;
  final String uid;
  final TweetType tweetType;
  final DateTime tweetedAt;
  final List<String> likes;
  final List<String> commentIds;
  final String id;
  final int reshareCount;
  final String retweetedBy;
  final String repliedTo;
  final String category;
  final String persuasiveMessage;

  const Tweet({
    required this.text,
    required this.hashtags,
    required this.link,
    required this.uid,
    required this.tweetType,
    required this.tweetedAt,
    required this.likes,
    required this.commentIds,
    required this.id,
    required this.reshareCount,
    required this.retweetedBy,
    required this.repliedTo,
    required this.category,
    required this.persuasiveMessage,
  });

  Tweet copyWith({
    String? text,
    List<String>? hashtags,
    String? link,
    String? uid,
    TweetType? tweetType,
    DateTime? tweetedAt,
    List<String>? likes,
    List<String>? commentIds,
    String? id,
    int? reshareCount,
    String? retweetedBy,
    String? repliedTo,
    String? category,
    String? persuasiveMessage,
  }) {
    return Tweet(
      text: text ?? this.text,
      hashtags: hashtags ?? this.hashtags,
      link: link ?? this.link,
      uid: uid ?? this.uid,
      tweetType: tweetType ?? this.tweetType,
      tweetedAt: tweetedAt ?? this.tweetedAt,
      likes: likes ?? this.likes,
      commentIds: commentIds ?? this.commentIds,
      id: id ?? this.id,
      reshareCount: reshareCount ?? this.reshareCount,
      retweetedBy: retweetedBy ?? this.retweetedBy,
      repliedTo: repliedTo ?? this.repliedTo,
      category: category ?? this.category,
      persuasiveMessage: persuasiveMessage ?? this.persuasiveMessage,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'text': text});
    result.addAll({'hashtags': hashtags});
    result.addAll({'link': link});
    result.addAll({'uid': uid});
    result.addAll({'tweetType': tweetType.type});
    result.addAll({'tweetedAt': tweetedAt.millisecondsSinceEpoch});
    result.addAll({'likes': likes});
    result.addAll({'commentIds': commentIds});
    result.addAll({'reshareCount': reshareCount});
    result.addAll({'retweetedBy': retweetedBy});
    result.addAll({'repliedTo': repliedTo});
    result.addAll({'category': category});
    result.addAll({'persuasiveMessage': persuasiveMessage});
  
    return result;
  }

  factory Tweet.fromMap(Map<String, dynamic> map) {
    return Tweet(
      text: map['text'] ?? '',
      hashtags: List<String>.from(map['hashtags']),
      link: map['link'] ?? '',
      uid: map['uid'] ?? '',
      tweetType: (map['tweetType'] as String).toTweetTypeEnum(),
      tweetedAt: DateTime.fromMillisecondsSinceEpoch(map['tweetedAt']),
      likes: List<String>.from(map['likes']),
      commentIds: List<String>.from(map['commentIds']),
      id: map['\$id'] ?? '',
      reshareCount: map['reshareCount']?.toInt() ?? 0,
      retweetedBy: map['retweetedBy'] ?? '',
      repliedTo: map['repliedTo'] ?? '',
      category: map['category'] ?? '',
      persuasiveMessage: map['persuasiveMessage'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Tweet(text: $text, hashtags: $hashtags, link: $link, uid: $uid, tweetType: $tweetType, tweetedAt: $tweetedAt, likes: $likes, commentIds: $commentIds, id: $id, reshareCount: $reshareCount, retweetedBy: $retweetedBy, repliedTo: $repliedTo, category: $category, persuasiveMessage: $persuasiveMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Tweet &&
        other.text == text &&
        listEquals(other.hashtags, hashtags) &&
        other.link == link &&
        other.uid == uid &&
        other.tweetType == tweetType &&
        other.tweetedAt == tweetedAt &&
        listEquals(other.likes, likes) &&
        listEquals(other.commentIds, commentIds) &&
        other.id == id &&
        other.reshareCount == reshareCount &&
        other.retweetedBy == retweetedBy &&
        other.repliedTo == repliedTo &&
        other.category == category && 
        other.persuasiveMessage == persuasiveMessage;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        hashtags.hashCode ^
        link.hashCode ^
        uid.hashCode ^
        tweetType.hashCode ^
        tweetedAt.hashCode ^
        likes.hashCode ^
        commentIds.hashCode ^
        id.hashCode ^
        reshareCount.hashCode ^
        retweetedBy.hashCode ^
        repliedTo.hashCode ^
        category.hashCode ^
        persuasiveMessage.hashCode;
  }
}