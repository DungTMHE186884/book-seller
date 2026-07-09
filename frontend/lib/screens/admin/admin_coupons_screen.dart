import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/order_provider.dart';
import '../../models/coupon_model.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'fixed'; // 'fixed' or 'percentage'
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchCoupons();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _codeController.clear();
    _valueController.clear();
    _selectedType = 'fixed';
    _isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thêm mã giảm giá mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã giảm giá (ví dụ: GIAM20) *',
                    hintText: 'Nhập chữ in hoa',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá *',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Số tiền cố định (đ)'),
                    ),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Phần trăm (%)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'percentage'
                        ? 'Giá trị giảm (%) *'
                        : 'Số tiền giảm (đ) *',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Kích hoạt sử dụng'),
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (val) {
                    setModalState(() => _isActive = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final code = _codeController.text.trim();
                final valText = _valueController.text.trim();

                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã giảm giá'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final val = double.tryParse(valText);
                if (val == null || val <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Giá trị giảm giá không hợp lệ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_selectedType == 'percentage' && val > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phần trăm giảm không được vượt quá 100%'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final orderProv = context.read<OrderProvider>();
                final ok = await orderProv.createCoupon(
                  code: code,
                  discountValue: val,
                  type: _selectedType,
                  isActive: _isActive,
                );

                if (ok && context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm mã giảm giá thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(orderProv.errorMessage ?? 'Có lỗi xảy ra'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCoupon(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mã giảm giá "$code"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final orderProv = context.read<OrderProvider>();
      final ok = await orderProv.deleteCoupon(id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa mã giảm giá!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      body: SafeArea(
        child: orderProv.isLoading && orderProv.coupons.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => orderProv.fetchCoupons(),
                child: orderProv.coupons.isEmpty
                    ? const Center(child: Text('Chưa có mã giảm giá nào.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProv.coupons.length,
                        itemBuilder: (ctx, i) {
                          final coupon = orderProv.coupons[i];
                          final isPercent = coupon.type == 'percentage';
                          final valueText = isPercent
                              ? '${coupon.discountValue.toStringAsFixed(0)}%'
                              : currencyFormat.format(coupon.discountValue);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: coupon.isActive
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                child: Icon(
                                  Icons.discount,
                                  color: coupon.isActive
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              title: Text(
                                coupon.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Giảm: $valueText'),
                                  Text(
                                    coupon.isActive
                                        ? 'Trạng thái: Đang áp dụng'
                                        : 'Trạng thái: Đã tắt',
                                    style: TextStyle(
                                      color: coupon.isActive
                                          ? const Color.fromARGB(
                                              255,
                                              14,
                                              91,
                                              16,
                                            )
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteCoupon(coupon.id, coupon.code),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
