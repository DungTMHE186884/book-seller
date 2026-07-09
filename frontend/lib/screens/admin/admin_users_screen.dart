import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchCustomers();
    });
  }

  void _toggleLock(int userId, String name, bool currentLocked) async {
    final actionText = currentLocked ? 'MỞ KHÓA' : 'KHÓA';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionText'),
        content: Text('Bạn có chắc chắn muốn $actionText tài khoản của khách hàng "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: currentLocked ? Colors.green : Colors.red),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<AuthProvider>().toggleCustomerLock(userId, !currentLocked);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ${currentLocked ? "mở khóa" : "khóa"} tài khoản thành công!'),
            backgroundColor: currentLocked ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: auth.isLoading && auth.customersList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => auth.fetchCustomers(),
                child: auth.customersList.isEmpty
                    ? const Center(child: Text('Chưa có khách hàng nào đăng ký.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: auth.customersList.length,
                        itemBuilder: (ctx, i) {
                          final customer = auth.customersList[i];
                          final isLocked = customer.status == 'locked';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isLocked ? Colors.red[100] : Colors.green[100],
                                child: Icon(
                                  isLocked ? Icons.lock : Icons.person,
                                  color: isLocked ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(
                                customer.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Username: @${customer.username}'),
                                  if (customer.phone != null) Text('SĐT: ${customer.phone}'),
                                  Text(
                                    'Trạng thái: ${isLocked ? "Đang bị khóa" : "Hoạt động"}',
                                    style: TextStyle(
                                      color: isLocked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isLocked ? Icons.lock_open : Icons.lock_outline,
                                  color: isLocked ? Colors.green : Colors.red,
                                ),
                                tooltip: isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                                onPressed: () => _toggleLock(customer.id, customer.fullName, isLocked),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
