import 'book_model.dart';

class OrderItemModel {
  final int id;
  final int bookId;
  final int quantity;
  final double price;
  final BookModel book;

  OrderItemModel({
    required this.id,
    required this.bookId,
    required this.quantity,
    required this.price,
    required this.book,
  });

  double get subtotal => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      bookId: json['book_id'] as int,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      book: BookModel.fromJson(json['book'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'quantity': quantity,
      'price': price,
      'book': book.toJson(),
    };
  }
}

class OrderModel {
  final int id;
  final int userId;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String deliveryMethod;
  final String paymentMethod;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status; // 'pending', 'preparing', 'delivering', 'delivered', 'cancelled'
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = itemsList
        .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      recipientName: json['recipient_name'] as String,
      recipientPhone: json['recipient_phone'] as String,
      recipientAddress: json['recipient_address'] as String,
      deliveryMethod: json['delivery_method'] as String? ?? 'Standard',
      paymentMethod: json['payment_method'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num? ?? 0.0).toDouble(),
      finalAmount: (json['final_amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'recipient_address': recipientAddress,
      'delivery_method': deliveryMethod,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
