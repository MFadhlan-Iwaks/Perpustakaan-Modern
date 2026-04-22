import 'package:flutter/material.dart';
import '../models/borrowing_model.dart';
import '../services/api_service.dart';

class BorrowingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Borrowing> _borrowings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Borrowing> get borrowings => _borrowings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBorrowings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _borrowings = await _apiService.fetchBorrowings();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}