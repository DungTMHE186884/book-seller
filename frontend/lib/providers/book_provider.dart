import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/author_model.dart';
import '../models/publisher_model.dart';
import '../models/review_model.dart';

class BookProvider extends ChangeNotifier {
  List<BookModel> books = [];
  List<BookModel> searchBooks = [];
  List<CategoryModel> categories = [];
  List<AuthorModel> authors = [];
  List<PublisherModel> publishers = [];

  // Specific Book Detail States
  BookModel? selectedBook;
  List<BookModel> relatedBooks = [];
  List<ReviewModel> reviews = [];

  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  Future<void> fetchCategories() async {
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.categories,
      );
      final list = response.data as List;
      categories = list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> fetchAuthors() async {
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.authors);
      final list = response.data as List;
      authors = list
          .map((e) => AuthorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> fetchPublishers() async {
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.publishers,
      );
      final list = response.data as List;
      publishers = list
          .map((e) => PublisherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> fetchBooks({
    String? query,
    int? categoryId,
    int? authorId,
    int? publisherId,
    String? sortBy,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.books,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (authorId != null) 'author_id': authorId,
          if (publisherId != null) 'publisher_id': publisherId,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );
      final list = response.data as List;
      books = list
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSearchBooks({
    String? query,
    int? categoryId,
    int? authorId,
    int? publisherId,
    String? sortBy,
  }) async {
    isSearching = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.books,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (authorId != null) 'author_id': authorId,
          if (publisherId != null) 'publisher_id': publisherId,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );
      final list = response.data as List;
      searchBooks = list
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
      isSearching = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookDetails(int bookId) async {
    isLoading = true;
    errorMessage = null;
    selectedBook = null;
    relatedBooks = [];
    reviews = [];
    notifyListeners();

    try {
      // 1. Fetch book details
      final bookResponse = await ApiClient.instance.dio.get(
        ApiConstants.bookDetail(bookId),
      );
      selectedBook = BookModel.fromJson(
        bookResponse.data as Map<String, dynamic>,
      );

      // 2. Fetch related books
      try {
        final relatedResponse = await ApiClient.instance.dio.get(
          ApiConstants.relatedBooks(bookId),
        );
        final relatedList = relatedResponse.data as List;
        relatedBooks = relatedList
            .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}

      // 3. Fetch reviews
      try {
        final reviewsResponse = await ApiClient.instance.dio.get(
          ApiConstants.bookReviews(bookId),
        );
        final reviewsList = reviewsResponse.data as List;
        reviews = reviewsList
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required int bookId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.reviews,
        data: {'book_id': bookId, 'rating': rating, 'comment': comment},
      );
      final newReview = ReviewModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      reviews.insert(0, newReview);

      // Reload book details to update overall rating score
      final bookResponse = await ApiClient.instance.dio.get(
        ApiConstants.bookDetail(bookId),
      );
      selectedBook = BookModel.fromJson(
        bookResponse.data as Map<String, dynamic>,
      );

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ---------- Admin CRUD Operations ----------

  Future<bool> createBook({
    required String title,
    required int authorId,
    required int categoryId,
    required int publisherId,
    String? isbn,
    required double price,
    double? discountPrice,
    String? description,
    required int stock,
    String? coverImage,
    required bool isBestSelling,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.books,
        data: {
          'title': title,
          'author_id': authorId,
          'category_id': categoryId,
          'publisher_id': publisherId,
          'isbn': isbn,
          'price': price,
          'discount_price': discountPrice,
          'description': description,
          'stock': stock,
          'cover_image': coverImage,
          'is_best_selling': isBestSelling,
        },
      );
      await fetchBooks();
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

  Future<bool> updateBook(int bookId, Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiClient.instance.dio.put(
        ApiConstants.bookDetail(bookId),
        data: data,
      );
      await fetchBooks();
      if (selectedBook?.id == bookId) {
        await fetchBookDetails(bookId);
      }
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

  Future<bool> deleteBook(int bookId) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.bookDetail(bookId));
      books.removeWhere((e) => e.id == bookId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBookStock(int bookId, int stock) async {
    try {
      final response = await ApiClient.instance.dio.patch(
        ApiConstants.updateBookStock(bookId),
        queryParameters: {'stock': stock},
      );
      final updatedBook = BookModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      final index = books.indexWhere((e) => e.id == bookId);
      if (index != -1) {
        books[index] = updatedBook;
      }
      if (selectedBook?.id == bookId) {
        selectedBook = updatedBook;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Categories CRUD Admin
  Future<bool> createCategory(String name) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.categories,
        data: {'name': name},
      );
      categories.add(
        CategoryModel.fromJson(response.data as Map<String, dynamic>),
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.categoryDetail(id));
      categories.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.categoryDetail(id),
        data: {'name': name},
      );
      final updated = CategoryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = categories.indexWhere((e) => e.id == id);
      if (index != -1) {
        categories[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Authors CRUD Admin
  Future<bool> createAuthor(String name, String? bio) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.authors,
        data: {'name': name, 'bio': bio},
      );
      authors.add(AuthorModel.fromJson(response.data as Map<String, dynamic>));
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAuthor(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.authorDetail(id));
      authors.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAuthor(int id, String name, String? bio) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.authorDetail(id),
        data: {'name': name, 'bio': bio},
      );
      final updated = AuthorModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = authors.indexWhere((e) => e.id == id);
      if (index != -1) {
        authors[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Publishers CRUD Admin
  Future<bool> createPublisher(String name, String? address) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.publishers,
        data: {'name': name, 'address': address},
      );
      publishers.add(
        PublisherModel.fromJson(response.data as Map<String, dynamic>),
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePublisher(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.publisherDetail(id));
      publishers.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePublisher(int id, String name, String? address) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.publisherDetail(id),
        data: {'name': name, 'address': address},
      );
      final updated = PublisherModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = publishers.indexWhere((e) => e.id == id);
      if (index != -1) {
        publishers[index] = updated;
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
