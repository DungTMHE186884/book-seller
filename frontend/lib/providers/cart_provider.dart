import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/cart_item_model.dart';
import '../models/book_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> cartItems = [];
  List<BookModel> wishlist = [];

  // Coupon state
  Map<String, dynamic>? appliedCoupon;

  bool isLoading = false;
  String? errorMessage;

  List<CartItemModel> get activeCartItems => cartItems.where((e) => !e.saveForLater).toList();
  List<CartItemModel> get savedForLaterItems => cartItems.where((e) => e.saveForLater).toList();

  double get totalAmount {
    return activeCartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get discountAmount {
    if (appliedCoupon == null) return 0.0;
    
    final type = appliedCoupon!['type'] as String;
    final value = (appliedCoupon!['discount_value'] as num).toDouble();

    if (type == 'percentage') {
      return totalAmount * (value / 100.0);
    } else {
      return value > totalAmount ? totalAmount : value;
    }
  }

  double get finalAmount {
    final diff = totalAmount - discountAmount;
    return diff < 0 ? 0.0 : diff;
  }

  Future<void> fetchCartItems() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.cart);
      final list = response.data as List;
      cartItems = list.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int bookId, {int quantity = 1}) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.cart,
        data: {'book_id': bookId, 'quantity': quantity},
      );
      await fetchCartItems();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCartItem(int itemId, {int? quantity, bool? saveForLater}) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.put(
        ApiConstants.cartItemDetail(itemId),
        data: {
          if (quantity != null) 'quantity': quantity,
          if (saveForLater != null) 'save_for_later': saveForLater,
        },
      );
      await fetchCartItems();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(int itemId) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.delete(ApiConstants.cartItemDetail(itemId));
      cartItems.removeWhere((e) => e.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> applyCoupon(String code) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.validateCoupon(code));
      appliedCoupon = response.data as Map<String, dynamic>;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      appliedCoupon = null;
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void removeCoupon() {
    appliedCoupon = null;
    notifyListeners();
  }

  Future<void> clearCart() async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.cart);
      cartItems.clear();
      appliedCoupon = null;
      notifyListeners();
    } catch (_) {}
  }

  // ---------- Wishlist Operations ----------

  Future<void> fetchWishlist() async {
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.wishlist);
      final list = response.data as List;
      wishlist = list.map((e) => BookModel.fromJson(e['book'] as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> toggleWishlist(BookModel book) async {
    final isWishlisted = wishlist.any((e) => e.id == book.id);
    try {
      if (isWishlisted) {
        await ApiClient.instance.dio.delete(ApiConstants.wishlistDetail(book.id));
        wishlist.removeWhere((e) => e.id == book.id);
      } else {
        await ApiClient.instance.dio.post(
          ApiConstants.wishlist,
          queryParameters: {'book_id': book.id},
        );
        wishlist.add(book);
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
