import 'author_model.dart';
import 'category_model.dart';
import 'publisher_model.dart';

class BookModel {
  final int id;
  final String title;
  final int authorId;
  final int categoryId;
  final int publisherId;
  final String? isbn;
  final double price;
  final double? discountPrice;
  final String? description;
  final int stock;
  final String? coverImage;
  final bool isBestSelling;
  final double rating;
  final DateTime createdAt;

  final AuthorModel? author;
  final CategoryModel? category;
  final PublisherModel? publisher;

  BookModel({
    required this.id,
    required this.title,
    required this.authorId,
    required this.categoryId,
    required this.publisherId,
    this.isbn,
    required this.price,
    this.discountPrice,
    this.description,
    required this.stock,
    this.coverImage,
    required this.isBestSelling,
    required this.rating,
    required this.createdAt,
    this.author,
    this.category,
    this.publisher,
  });

  double get effectivePrice => discountPrice != null ? discountPrice! : price;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as int,
      title: json['title'] as String,
      authorId:
          json['author_id'] ??
          (json['author'] != null ? json['author']['id'] as int : 0),
      categoryId:
          json['category_id'] ??
          (json['category'] != null ? json['category']['id'] as int : 0),
      publisherId:
          json['publisher_id'] ??
          (json['publisher'] != null ? json['publisher']['id'] as int : 0),
      isbn: json['isbn'] as String?,
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      stock: json['stock'] as int,
      coverImage: json['cover_image'] as String?,
      isBestSelling: json['is_best_selling'] as bool? ?? false,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? AuthorModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      publisher: json['publisher'] != null
          ? PublisherModel.fromJson(json['publisher'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author_id': authorId,
      'category_id': categoryId,
      'publisher_id': publisherId,
      'isbn': isbn,
      'price': price,
      'discount_price': discountPrice,
      'description': description,
      'stock': stock,
      'cover_image': coverImage,
      'is_best_selling': isBestSelling,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'author': author?.toJson(),
      'category': category?.toJson(),
      'publisher': publisher?.toJson(),
    };
  }
}
