import 'package:flutter/foundation.dart';

class ApiConstants {
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
  ).isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)
          ? 'http://127.0.0.1:8000'
          : 'http://10.0.2.2:8000';

  // Auth
  static const String login = '/auth/login';
  static const String loginJson = '/auth/login-json';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Books
  static const String books = '/books';
  static String bookDetail(int id) => '/books/$id';
  static String relatedBooks(int id) => '/books/$id/related';
  static String updateBookStock(int id) => '/books/$id/stock';
  static String updateBookPrice(int id) => '/books/$id/price';

  // Categories, Authors, Publishers
  static const String categories = '/categories';
  static String categoryDetail(int id) => '/categories/$id';
  static const String authors = '/authors';
  static String authorDetail(int id) => '/authors/$id';
  static const String publishers = '/publishers';
  static String publisherDetail(int id) => '/publishers/$id';

  // Cart
  static const String cart = '/cart';
  static String cartItemDetail(int id) => '/cart/$id';

  // Coupons
  static const String coupons = '/coupons';
  static String validateCoupon(String code) => '/coupons/validate/$code';
  static String deleteCoupon(int id) => '/coupons/$id';

  // Orders
  static const String orders = '/orders';
  static const String allOrdersAdmin = '/orders/all';
  static String orderDetail(int id) => '/orders/$id';
  static String updateOrderStatus(int id) => '/orders/$id/status';
  static String cancelOrder(int id) => '/orders/$id/cancel';

  // Users (Admin lock/list)
  static const String updateProfile = '/users/profile';
  static const String customersAdmin = '/users/customers';
  static String updateUserStatusAdmin(int id) => '/users/$id/status';

  // Wishlist
  static const String wishlist = '/users/wishlist';
  static String wishlistDetail(int id) => '/users/wishlist/$id';

  // Reviews
  static const String reviews = '/reviews';
  static String bookReviews(int id) => '/reviews/book/$id';
}
