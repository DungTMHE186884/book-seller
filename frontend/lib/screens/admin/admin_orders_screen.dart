import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

/// Admin screen to manage customer orders.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial orders after widget build completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchAdminOrders();
    });
  }

  // Show detailed sales invoice dialog for the given order.
  void _showInvoiceDialog(OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hóa Đơn Bán Hàng'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Text(
                    'ĐỘC BẢN SÁCH BOOKSTORE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Center(
                  child: Text(
                    'Địa chỉ: 144 Xuân Thủy, Cầu Giấy, Hà Nội\nHotline: 19001008',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const Divider(height: 20),
                Text(
                  'Mã đơn hàng: #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal())}',
                ),
                Text('Khách hàng: ${order.recipientName}'),
                Text('SĐT liên hệ: ${order.recipientPhone}'),
                Text('Địa chỉ nhận: ${order.recipientAddress}'),
                const Divider(height: 20),
                const Text(
                  'Danh sách sản phẩm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.book.title} (x${item.quantity})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(currencyFormat.format(item.subtotal)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền sách:'),
                    Text(currencyFormat.format(order.totalAmount)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mã giảm giá coupon:'),
                    Text(
                      '-${currencyFormat.format(order.discountAmount)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TỔNG THANH TOÁN:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currencyFormat.format(order.finalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Show bottom sheet to select and update order status.
  void _changeStatus(int orderId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Cập nhật trạng thái đơn hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange,
                ),
                title: const Text('Chờ xác nhận (Pending)'),
                selected: currentStatus == 'pending',
                onTap: () => _updateStatus(orderId, 'pending', ctx),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: Colors.blue),
                title: const Text('Đang chuẩn bị (Preparing)'),
                selected: currentStatus == 'preparing',
                onTap: () => _updateStatus(orderId, 'preparing', ctx),
              ),
              ListTile(
                leading: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.purple,
                ),
                title: const Text('Đang giao hàng (Delivering)'),
                selected: currentStatus == 'delivering',
                onTap: () => _updateStatus(orderId, 'delivering', ctx),
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                title: const Text('Đã giao (Delivered)'),
                selected: currentStatus == 'delivered',
                onTap: () => _updateStatus(orderId, 'delivered', ctx),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Hủy đơn hàng (Cancelled)'),
                selected: currentStatus == 'cancelled',
                onTap: () => _updateStatus(orderId, 'cancelled', ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // Update order status via OrderProvider.
  void _updateStatus(
    int orderId,
    String newStatus,
    BuildContext bottomSheetCtx,
  ) async {
    Navigator.of(bottomSheetCtx).pop(); // close bottomsheet
    final ok = await context.read<OrderProvider>().updateOrderStatus(
      orderId,
      newStatus,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái đơn hàng sang "$newStatus"!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch OrderProvider state to rebuild UI on changes.
    final orderProv = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      body: SafeArea(
        child: orderProv.isLoading && orderProv.adminOrders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => orderProv.fetchAdminOrders(),
                child: orderProv.adminOrders.isEmpty
                    ? const Center(
                        child: Text('Chưa có đơn hàng nào từ khách hàng.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProv.adminOrders.length,
                        itemBuilder: (ctx, i) {
                          final order = orderProv.adminOrders[i];
                          Color statusColor = Colors.orange;
                          if (order.status == 'delivered')
                            statusColor = Colors.green;
                          if (order.status == 'cancelled')
                            statusColor = Colors.red;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Đơn hàng #${order.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        order.statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Người nhận: ${order.recipientName} - SĐT: ${order.recipientPhone}',
                                  ),
                                  Text('Địa chỉ: ${order.recipientAddress}'),
                                  Text(
                                    'Thanh toán: ${order.paymentMethod.toUpperCase()} | Vận chuyển: ${order.deliveryMethod}',
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tổng: ${currencyFormat.format(order.finalAmount)}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.receipt,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Xem hóa đơn',
                                            onPressed: () =>
                                                _showInvoiceDialog(order),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_note,
                                              color: Colors.purple,
                                            ),
                                            tooltip: 'Đổi trạng thái',
                                            onPressed: () => _changeStatus(
                                              order.id,
                                              order.status,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
