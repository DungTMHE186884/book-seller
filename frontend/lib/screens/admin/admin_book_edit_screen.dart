import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../providers/book_provider.dart';

class AdminBookEditScreen extends StatefulWidget {
  final BookModel? book;

  const AdminBookEditScreen({super.key, this.book});

  @override
  State<AdminBookEditScreen> createState() => _AdminBookEditScreenState();
}

class _AdminBookEditScreenState extends State<AdminBookEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _coverImageController = TextEditingController();
  
  int? _selectedAuthorId;
  int? _selectedCategoryId;
  int? _selectedPublisherId;
  bool _isBestSelling = false;

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    // Load options
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bookProv = context.read<BookProvider>();
      await Future.wait([
        bookProv.fetchCategories(),
        bookProv.fetchAuthors(),
        bookProv.fetchPublishers(),
      ]);

      if (isEditing) {
        final b = widget.book!;
        _titleController.text = b.title;
        _isbnController.text = b.isbn ?? '';
        _priceController.text = '${b.price}';
        _discountPriceController.text = b.discountPrice != null ? '${b.discountPrice}' : '';
        _descriptionController.text = b.description ?? '';
        _stockController.text = '${b.stock}';
        _coverImageController.text = b.coverImage ?? '';
        _selectedAuthorId = b.authorId;
        _selectedCategoryId = b.categoryId;
        _selectedPublisherId = b.publisherId;
        _isBestSelling = b.isBestSelling;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAuthorId == null || _selectedCategoryId == null || _selectedPublisherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tác giả, thể loại và nhà xuất bản!'), backgroundColor: Colors.red),
      );
      return;
    }

    final bookProv = context.read<BookProvider>();
    final double price = double.parse(_priceController.text);
    final double? discountPrice = _discountPriceController.text.trim().isEmpty
        ? null
        : double.parse(_discountPriceController.text);
    final int stock = int.parse(_stockController.text);

    bool success;
    if (isEditing) {
      success = await bookProv.updateBook(
        widget.book!.id,
        {
          'title': _titleController.text.trim(),
          'author_id': _selectedAuthorId,
          'category_id': _selectedCategoryId,
          'publisher_id': _selectedPublisherId,
          'isbn': _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
          'price': price,
          'discount_price': discountPrice,
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'stock': stock,
          'cover_image': _coverImageController.text.trim().isEmpty ? null : _coverImageController.text.trim(),
          'is_best_selling': _isBestSelling,
        },
      );
    } else {
      success = await bookProv.createBook(
        title: _titleController.text.trim(),
        authorId: _selectedAuthorId!,
        categoryId: _selectedCategoryId!,
        publisherId: _selectedPublisherId!,
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        price: price,
        discountPrice: discountPrice,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        stock: stock,
        coverImage: _coverImageController.text.trim().isEmpty ? null : _coverImageController.text.trim(),
        isBestSelling: _isBestSelling,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật sách!' : 'Đã thêm sách mới thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookProv.errorMessage ?? 'Có lỗi xảy ra khi lưu sách!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa thông tin sách' : 'Thêm sách mới'),
      ),
      body: SafeArea(
        child: bookProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Tên sách *'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nhập tên sách' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Dropdowns
                      DropdownButtonFormField<int>(
                        value: _selectedAuthorId,
                        decoration: const InputDecoration(labelText: 'Tác giả *'),
                        items: bookProv.authors.map((a) {
                          return DropdownMenuItem<int>(value: a.id, child: Text(a.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedAuthorId = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Thể loại *'),
                        items: bookProv.categories.map((c) {
                          return DropdownMenuItem<int>(value: c.id, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: _selectedPublisherId,
                        decoration: const InputDecoration(labelText: 'Nhà xuất bản *'),
                        items: bookProv.publishers.map((p) {
                          return DropdownMenuItem<int>(value: p.id, child: Text(p.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPublisherId = val),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _isbnController,
                        decoration: const InputDecoration(labelText: 'ISBN'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Giá bán *'),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Nhập giá bán';
                                if (double.tryParse(val) == null) return 'Giá trị không hợp lệ';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountPriceController,
                              decoration: const InputDecoration(labelText: 'Giá khuyến mãi'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Số lượng tồn kho *'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Nhập số lượng kho';
                          if (int.tryParse(val) == null) return 'Giá trị không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _coverImageController,
                        decoration: const InputDecoration(labelText: 'Link hình ảnh bìa'),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Mô tả nội dung'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        title: const Text('Đánh dấu là sách Bán chạy (Best Selling)'),
                        value: _isBestSelling,
                        onChanged: (val) => setState(() => _isBestSelling = val),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('LƯU THÔNG TIN SÁCH'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
