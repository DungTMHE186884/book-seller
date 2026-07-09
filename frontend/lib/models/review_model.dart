class ReviewModel {
  final int id;
  final int userId;
  final int bookId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String userUsername;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.userUsername,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      bookId: json['book_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userUsername: json['user_username'] as String? ?? 'Khách',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'user_username': userUsername,
    };
  }
}
