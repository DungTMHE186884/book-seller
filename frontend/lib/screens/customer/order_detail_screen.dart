import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
    });
  }

  Widget _buildTimelineStep({
    required String title,
    required String desc,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconColor = isCompleted
        ? Colors.green
        : (isCurrent ? Colors.orange : Colors.grey);
    IconData icon = isCompleted ? Icons.check_circle : Icons.radio_button_unchecked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.orange[800] : (isCompleted ? Colors.black : Colors.grey),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Quay lại')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<OrderProvider>().cancelOrder(widget.orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn hàng đã được hủy!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (orderProv.isLoading || orderProv.selectedOrder == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = orderProv.selectedOrder!;
    final isCancelable = order.status == 'pending' || order.status == 'preparing';

    // Timeline mapping
    final statusList = ['pending', 'preparing', 'delivering', 'delivered'];
    final currentStatusIdx = statusList.indexOf(order.status);
    final isCancelled = order.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Đơn Hàng #${order.id}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trạng thái theo dõi đơn hàng
              const Text('Theo dõi đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isCancelled
                      ? Row(
                          children: const [
                            Icon(Icons.cancel, color: Colors.red, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Đơn hàng này đã được HỦY',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                            )
                          ],
                        )
                      : Column(
                          children: [
                            _buildTimelineStep(
                              title: 'Chờ xác nhận',
                              desc: 'Hệ thống đã nhận đơn hàng của bạn',
                              isCompleted: currentStatusIdx > 0,
                              isCurrent: currentStatusIdx == 0,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              title: 'Đang chuẩn bị',
                              desc: 'Sách đang được đóng gói gửi bưu điện',
                              isCompleted: currentStatusIdx > 1,
                              isCurrent: currentStatusIdx == 1,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              title: 'Đang giao hàng',
                              desc: 'Đơn hàng đang trên đường tới địa chỉ nhận',
                              isCompleted: currentStatusIdx > 2,
                              isCurrent: currentStatusIdx == 2,
                              isLast: false,
                            ),
                            _buildTimelineStep(
                              title: 'Đã nhận sách',
                              desc: 'Giao hàng thành công',
                              isCompleted: currentStatusIdx == 3,
                              isCurrent: currentStatusIdx == 3,
                              isLast: true,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Shipping information
              const Text('Địa chỉ giao nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('SĐT: ${order.recipientPhone}', style: TextStyle(color: Colors.grey[850])),
                      const SizedBox(height: 4),
                      Text('Địa chỉ: ${order.recipientAddress}', style: TextStyle(color: Colors.grey[850])),
                      const Divider(height: 24),
                      Text('Vận chuyển: ${order.deliveryMethod}', style: const TextStyle(fontSize: 13)),
                      Text('Thanh toán: ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Order Items Invoice
              const Text('Danh sách sách đã mua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (ctx, i) {
                  final item = order.items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.book.coverImage ?? 'https://picsum.photos/id/101/200/300',
                          width: 40,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(item.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${currencyFormat.format(item.price)} x${item.quantity}'),
                      trailing: Text(
                        currencyFormat.format(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Pricing Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tạm tính sách:'),
                          Text(currencyFormat.format(order.totalAmount)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã giảm giá coupon:'),
                          Text('-${currencyFormat.format(order.discountAmount)}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            currencyFormat.format(order.finalAmount),
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cancel button for customers
              if (isCancelable && !isCancelled) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _cancel,
                  child: const Text('HỦY ĐƠN HÀNG NÀY'),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
