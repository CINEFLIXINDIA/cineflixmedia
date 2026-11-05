class RatingModel {
  final int postId;
  final double averageRating;
  final int totalRatings;
  final int? userRating;

  const RatingModel({
    required this.postId,
    required this.averageRating,
    required this.totalRatings,
    this.userRating,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    int postId = 0;
    if (json['post_id'] is int) {
      postId = json['post_id'];
    } else if (json['post_id'] != null) {
      postId = int.tryParse(json['post_id'].toString()) ?? 0;
    }

    double averageRating = 0.0;
    if (json['average_rating'] is num) {
      averageRating = (json['average_rating'] as num).toDouble();
    } else if (json['average_rating'] != null) {
      averageRating = double.tryParse(json['average_rating'].toString()) ?? 0.0;
    }

    int totalRatings = 0;
    if (json['total_ratings'] is int) {
      totalRatings = json['total_ratings'];
    } else if (json['total_ratings'] != null) {
      totalRatings = int.tryParse(json['total_ratings'].toString()) ?? 0;
    }

    int? userRating;
    if (json['user_rating'] is int) {
      userRating = json['user_rating'];
    } else if (json['user_rating'] != null) {
      userRating = int.tryParse(json['user_rating'].toString());
    }

    return RatingModel(
      postId: postId,
      averageRating: averageRating,
      totalRatings: totalRatings,
      userRating: userRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'user_rating': userRating,
    };
  }

  RatingModel copyWith({
    int? postId,
    double? averageRating,
    int? totalRatings,
    int? userRating,
  }) {
    return RatingModel(
      postId: postId ?? this.postId,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      userRating: userRating ?? this.userRating,
    );
  }
}

