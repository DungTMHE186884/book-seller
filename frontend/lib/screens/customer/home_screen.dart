import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/cart_badge_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().fetchCategories();
      context.read<BookProvider>().fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookProv = context.watch<BookProvider>();
    final theme = Theme.of(context);

    final bestSellers = bookProv.books.where((b) => b.isBestSelling).toList();
    final displayedBooks = _selectedCategoryId == null
        ? bookProv.books
        : bookProv.books
              .where((b) => b.categoryId == _selectedCategoryId)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, 👋',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            Text(
              auth.currentUser?.fullName ?? 'Khách',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: const [CartBadgeButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<BookProvider>().fetchCategories();
          await context.read<BookProvider>().fetchBooks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories scroll horizontal
              const Text(
                'Danh mục sách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryId = null);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ...bookProv.categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: _selectedCategoryId == cat.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? cat.id : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Best sellers section
              if (bestSellers.isNotEmpty && _selectedCategoryId == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sách Bán Chạy 🔥',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 310,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: bestSellers.length,
                    itemBuilder: (ctx, i) =>
                        BookCard(book: bestSellers[i], width: 140),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Books grid or list
              Text(
                _selectedCategoryId == null
                    ? 'Gợi Ý Cho Bạn'
                    : 'Danh Sách Sách',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (bookProv.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (displayedBooks.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: const Text(
                    'Không tìm thấy sách nào thuộc danh mục này.',
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900
                        ? 5
                        : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 900
                        ? 0.54
                        : (MediaQuery.of(context).size.width > 600
                              ? 0.52
                              : 0.46),
                  ),
                  itemCount: displayedBooks.length,
                  itemBuilder: (ctx, i) =>
                      BookCard(book: displayedBooks[i], width: double.infinity),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
