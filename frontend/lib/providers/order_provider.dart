import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/order_model.dart';
import '../models/coupon_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> orders = [];
  List<OrderModel> adminOrders = [];
  OrderModel? selectedOrder;
  List<CouponModel> coupons = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchUserOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.orders);
      final list = response.data as List;
      orders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.allOrdersAdmin);
      final list = response.data as List;
      adminOrders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetail(int orderId) async {
    isLoading = true;
    errorMessage = null;
    selectedOrder = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.orderDetail(orderId));
      selectedOrder = OrderModel.fromJson(response.data as Map<String, dynamic>);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required String paymentMethod, // 'cod', 'transfer', 'wallet', 'card'
    String deliveryMethod = 'Standard',
    String? couponCode,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.orders,
        data: {
          'recipient_name': recipientName,
          'recipient_phone': recipientPhone,
          'recipient_address': recipientAddress,
          'payment_method': paymentMethod,
          'delivery_method': deliveryMethod,
          if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        },
      );
      final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
      orders.insert(0, order);
      isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    errorMessage = null;
    try {
      final response = await ApiClient.instance.dio.put(ApiConstants.cancelOrder(orderId));
      final updatedOrder = OrderModel.fromJson(response.data as Map<String, dynamic>);
      
      // Update local cache lists
      final index = orders.indexWhere((e) => e.id == orderId);
      if (index != -1) {
        orders[index] = updatedOrder;
      }
      final adminIndex = adminOrders.indexWhere((e) => e.id == orderId);
      if (adminIndex != -1) {
        adminOrders[adminIndex] = updatedOrder;
      }
      if (selectedOrder?.id == orderId) {
        selectedOrder = updatedOrder;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ---------- Admin Operations ----------

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    errorMessage = null;
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.updateOrderStatus(orderId),
        data: {'status': newStatus},
      );
      final updatedOrder = OrderModel.fromJson(response.data as Map<String, dynamic>);
      
      final index = adminOrders.indexWhere((e) => e.id == orderId);
      if (index != -1) {
        adminOrders[index] = updatedOrder;
      }
      final userIndex = orders.indexWhere((e) => e.id == orderId);
      if (userIndex != -1) {
        orders[userIndex] = updatedOrder;
      }
      if (selectedOrder?.id == orderId) {
        selectedOrder = updatedOrder;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ---------- Coupon Management (Admin only) ----------

  Future<void> fetchCoupons() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.coupons);
      final list = response.data as List;
      coupons = list.map((e) => CouponModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCoupon({
    required String code,
    required double discountValue,
    required String type,
    bool isActive = true,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.coupons,
        data: {
          'code': code.toUpperCase(),
          'discount_value': discountValue,
          'type': type,
          'is_active': isActive,
        },
      );
      coupons.add(CouponModel.fromJson(response.data as Map<String, dynamic>));
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCoupon(int id) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.delete(ApiConstants.deleteCoupon(id));
      coupons.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
