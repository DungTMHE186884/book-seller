import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../../models/category_model.dart';
import '../../models/author_model.dart';
import '../../models/publisher_model.dart';
import '../../widgets/cart_badge_button.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  int? _tempCategoryId;
  int? _tempAuthorId;
  int? _tempPublisherId;
  String? _tempSortBy;

  int? _activeCategoryId;
  int? _activeAuthorId;
  int? _activePublisherId;
  String? _activeSortBy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().fetchAuthors();
      context.read<BookProvider>().fetchPublishers();
      context.read<BookProvider>().fetchCategories();
      // Load initial books
      context.read<BookProvider>().fetchSearchBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<BookProvider>().fetchSearchBooks(
      query: _searchController.text.trim(),
      categoryId: _activeCategoryId,
      authorId: _activeAuthorId,
      publisherId: _activePublisherId,
      sortBy: _activeSortBy,
    );
  }

  void _showFilterSheet() {
    final bookProv = context.read<BookProvider>();

    // Initialize temporary states with current active states
    setState(() {
      _tempCategoryId = _activeCategoryId;
      _tempAuthorId = _activeAuthorId;
      _tempPublisherId = _activePublisherId;
      _tempSortBy = _activeSortBy;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bộ lọc & Sắp xếp',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _tempCategoryId = null;
                                _tempAuthorId = null;
                                _tempPublisherId = null;
                                _tempSortBy = null;
                              });
                            },
                            child: const Text('Đặt lại'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Sắp xếp
                      const Text(
                        'Sắp xếp theo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Giá: Thấp → Cao'),
                            selected: _tempSortBy == 'price_asc',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'price_asc' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Bán chạy'),
                            selected: _tempSortBy == 'best_selling',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'best_selling' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Sách mới'),
                            selected: _tempSortBy == 'newest',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'newest' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Đánh giá cao'),
                            selected: _tempSortBy == 'rating',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'rating' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Thể loại
                      const Text(
                        'Thể loại',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempCategoryId,
                        isExpanded: true,
                        hint: const Text('Chọn thể loại'),
                        items: bookProv.categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => _tempCategoryId = val),
                      ),
                      const SizedBox(height: 20),

                      // Tác giả
                      const Text(
                        'Tác giả',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempAuthorId,
                        isExpanded: true,
                        hint: const Text('Chọn tác giả'),
                        items: bookProv.authors.map((a) {
                          return DropdownMenuItem<int>(
                            value: a.id,
                            child: Text(a.name),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => _tempAuthorId = val),
                      ),
                      const SizedBox(height: 20),

                      // Nhà xuất bản
                      const Text(
                        'Nhà xuất bản',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempPublisherId,
                        isExpanded: true,
                        hint: const Text('Chọn nhà xuất bản'),
                        items: bookProv.publishers.map((p) {
                          return DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => _tempPublisherId = val),
                      ),
                      const SizedBox(height: 36),

                      // Apply button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeCategoryId = _tempCategoryId;
                            _activeAuthorId = _tempAuthorId;
                            _activePublisherId = _tempPublisherId;
                            _activeSortBy = _tempSortBy;
                          });
                          _triggerSearch();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('ÁP DỤNG BỘ LỌC'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám Phá Sách'),
        elevation: 0,
        actions: const [CartBadgeButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Search input & Filter trigger
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _triggerSearch(),
                      decoration: InputDecoration(
                        hintText: 'Tên sách, tác giả, thể loại, ISBN...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _triggerSearch();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(
                          () {},
                        ); // updates suffix clear button visibility
                        _triggerSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  Stack(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilterSheet,
                      ),
                      if (_activeCategoryId != null ||
                          _activeAuthorId != null ||
                          _activePublisherId != null ||
                          _activeSortBy != null)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active filter tags (if any)
              if (_activeCategoryId != null ||
                  _activeAuthorId != null ||
                  _activePublisherId != null ||
                  _activeSortBy != null) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_activeSortBy != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text('Sắp xếp: $_activeSortBy'),
                            onDeleted: () {
                              setState(() => _activeSortBy = null);
                              _triggerSearch();
                            },
                          ),
                        ),
                      if (_activeCategoryId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.categories
                                  .firstWhere((e) => e.id == _activeCategoryId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activeCategoryId = null);
                              _triggerSearch();
                            },
                          ),
                        ),
                      if (_activeAuthorId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.authors
                                  .firstWhere((e) => e.id == _activeAuthorId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activeAuthorId = null);
                              _triggerSearch();
                            },
                          ),
                        ),
                      if (_activePublisherId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.publishers
                                  .firstWhere((e) => e.id == _activePublisherId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activePublisherId = null);
                              _triggerSearch();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Results grid
              Expanded(
                child: bookProv.searchBooks.isEmpty
                    ? (bookProv.isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy cuốn sách nào khớp với tìm kiếm',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ))
                    : RefreshIndicator(
                        onRefresh: () async => _triggerSearch(),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 900
                                    ? 5
                                    : (MediaQuery.of(context).size.width > 600
                                          ? 3
                                          : 2),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio:
                                    MediaQuery.of(context).size.width > 900
                                    ? 0.54
                                    : (MediaQuery.of(context).size.width > 600
                                          ? 0.52
                                          : 0.46),
                              ),
                          itemCount: bookProv.searchBooks.length,
                          itemBuilder: (ctx, i) => BookCard(
                            book: bookProv.searchBooks[i],
                            width: double.infinity,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
