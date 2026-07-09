import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/book_provider.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _extraController = TextEditingController(); // bio or address

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BookProvider>();
      p.fetchCategories();
      p.fetchAuthors();
      p.fetchPublishers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _showAddDialog(int type) {
    // type: 0 = Category, 1 = Author, 2 = Publisher
    _nameController.clear();
    _extraController.clear();

    String title = '';
    String extraLabel = '';
    bool showExtra = false;

    if (type == 0) {
      title = 'Thêm thể loại mới';
    } else if (type == 1) {
      title = 'Thêm tác giả mới';
      extraLabel = 'Tiểu sử / Mô tả';
      showExtra = true;
    } else {
      title = 'Thêm nhà xuất bản mới';
      extraLabel = 'Địa chỉ';
      showExtra = true;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên hiển thị *'),
            ),
            if (showExtra) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _extraController,
                decoration: InputDecoration(labelText: extraLabel),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final p = context.read<BookProvider>();
              bool ok = false;

              if (type == 0) {
                ok = await p.createCategory(name);
              } else if (type == 1) {
                ok = await p.createAuthor(
                  name,
                  _extraController.text.trim().isEmpty
                      ? null
                      : _extraController.text.trim(),
                );
              } else {
                ok = await p.createPublisher(
                  name,
                  _extraController.text.trim().isEmpty
                      ? null
                      : _extraController.text.trim(),
                );
              }

              if (ok && context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thêm thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    int type,
    int id,
    String currentName,
    String? currentExtra,
  ) {
    _nameController.text = currentName;
    _extraController.text = currentExtra ?? '';

    String title = '';
    String extraLabel = '';
    bool showExtra = false;

    if (type == 0) {
      title = 'Sửa thể loại';
    } else if (type == 1) {
      title = 'Sửa thông tin tác giả';
      extraLabel = 'Tiểu sử / Mô tả';
      showExtra = true;
    } else {
      title = 'Sửa thông tin nhà xuất bản';
      extraLabel = 'Địa chỉ';
      showExtra = true;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên hiển thị *'),
            ),
            if (showExtra) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _extraController,
                decoration: InputDecoration(labelText: extraLabel),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final p = context.read<BookProvider>();
              bool ok = false;

              if (type == 0) {
                ok = await p.updateCategory(id, name);
              } else if (type == 1) {
                ok = await p.updateAuthor(
                  id,
                  name,
                  _extraController.text.trim().isEmpty
                      ? null
                      : _extraController.text.trim(),
                );
              } else {
                ok = await p.updatePublisher(
                  id,
                  name,
                  _extraController.text.trim().isEmpty
                      ? null
                      : _extraController.text.trim(),
                );
              }

              if (ok && context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int type, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "$name"?'),
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
      final p = context.read<BookProvider>();
      bool ok = false;

      if (type == 0) {
        ok = await p.deleteCategory(id);
      } else if (type == 1) {
        ok = await p.deleteAuthor(id);
      } else {
        ok = await p.deletePublisher(id);
      }

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khỏi hệ thống!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // hide appbar title, we only need tabs
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thể loại'),
            Tab(text: 'Tác giả'),
            Tab(text: 'Nhà xuất bản'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories list
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookProv.categories.length,
            itemBuilder: (ctx, i) {
              final cat = bookProv.categories[i];
              return Card(
                child: ListTile(
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () =>
                            _showEditDialog(0, cat.id, cat.name, null),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteItem(0, cat.id, cat.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Authors list
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookProv.authors.length,
            itemBuilder: (ctx, i) {
              final aut = bookProv.authors[i];
              return Card(
                child: ListTile(
                  title: Text(
                    aut.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(aut.bio ?? 'Chưa cập nhật tiểu sử'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () =>
                            _showEditDialog(1, aut.id, aut.name, aut.bio),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteItem(1, aut.id, aut.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Publishers list
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookProv.publishers.length,
            itemBuilder: (ctx, i) {
              final pub = bookProv.publishers[i];
              return Card(
                child: ListTile(
                  title: Text(
                    pub.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(pub.address ?? 'Chưa cập nhật địa chỉ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () =>
                            _showEditDialog(2, pub.id, pub.name, pub.address),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteItem(2, pub.id, pub.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(_tabController.index),
        child: const Icon(Icons.add),
      ),
    );
  }
}
