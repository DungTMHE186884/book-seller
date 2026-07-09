import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../core/secure_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiClient.instance.onUnauthorized = logout;
  }

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  // Admin managed state
  List<UserModel> customersList = [];

  Future<void> tryAutoLogin() async {
    final token = await SecureStorage.instance.readToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.me);
      currentUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      status = AuthStatus.authenticated;
    } catch (_) {
      await SecureStorage.instance.deleteToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.loginJson,
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await SecureStorage.instance.saveToken(token);
      currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    String? address,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'password': password,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'address': address,
        },
      );
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

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.updateProfile,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      currentUser = UserModel.fromJson(response.data as Map<String, dynamic>);
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

  Future<void> logout() async {
    await SecureStorage.instance.deleteToken();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    customersList.clear();
    notifyListeners();
  }

  // ---------- Admin Operations ----------

  Future<void> fetchCustomers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.customersAdmin);
      final list = response.data as List;
      customersList = list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleCustomerLock(int userId, bool lock) async {
    errorMessage = null;
    try {
      final statusStr = lock ? 'locked' : 'active';
      final response = await ApiClient.instance.dio.put(
        ApiConstants.updateUserStatusAdmin(userId),
        queryParameters: {'status': statusStr},
      );
      final updatedUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      
      final index = customersList.indexWhere((e) => e.id == userId);
      if (index != -1) {
        customersList[index] = updatedUser;
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
