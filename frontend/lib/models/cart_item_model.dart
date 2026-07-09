import 'book_model.dart';

class CartItemModel {
  final int id;
  final int userId;
  final int bookId;
  final int quantity;
  final bool saveForLater;
  final BookModel book;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    required this.saveForLater,
    required this.book,
  });

  double get subtotal => book.effectivePrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      bookId: json['book_id'] as int,
      quantity: json['quantity'] as int,
      saveForLater: json['save_for_later'] as bool? ?? false,
      book: BookModel.fromJson(json['book'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
      'save_for_later': saveForLater,
      'book': book.toJson(),
    };
  }
}
