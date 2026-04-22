import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/borrowing_model.dart';
import '../models/user_model.dart';

class ApiService {
  static const String serverUrl = 'http://10.0.2.2:5000';
  static const String baseUrl = '$serverUrl/api';
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _legacyTokenKey = 'jwt_token';
  static const String _userNameKey = 'userName';

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey) ?? prefs.getString(_legacyTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getSavedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken, {String? userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_legacyTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    if (userName != null && userName.isNotEmpty) {
      await prefs.setString(_userNameKey, userName);
    }
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_userNameKey);
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _authOnlyHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
    };
  }

  String _extractMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {
    }
    return fallback;
  }

  String? _buildImageUrl(dynamic imageValue) {
    if (imageValue == null) return null;

    final image = imageValue.toString().trim();
    if (image.isEmpty) return null;

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    final cleanPath = image.startsWith('/') ? image.substring(1) : image;
    return '$serverUrl/uploads/$cleanPath';
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    final message = _extractMessage(response, 'Registrasi gagal');
    throw Exception('HTTP ${response.statusCode}: $message');
  }
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken']?.toString();
        final refreshToken = data['refreshToken']?.toString();
        final userName = data['user'] is Map<String, dynamic>
            ? data['user']['name']?.toString()
            : null;
        if (accessToken == null || accessToken.isEmpty) {
          return false;
        }

        await _saveTokens(accessToken, refreshToken, userName: userName);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': refreshToken}),
        );
      } catch (_) {
      }
    }

    await _clearTokens();
  }
  Future<List<Book>> fetchBooks() async {
    final token = await getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) {
          final Map<String, dynamic> normalizedData = Map<String, dynamic>.from(data);
          normalizedData['image'] = _buildImageUrl(normalizedData['image']);
          return Book.fromJson(normalizedData);
        }).toList();
      }

      final message = _extractMessage(response, 'Gagal mengambil data buku dari server');

      throw Exception('HTTP ${response.statusCode}: $message');
    } catch (e) {
      throw Exception('Tidak bisa mengambil buku: $e');
    }
  }

  Future<void> addBook({
    required String title,
    required String author,
    required int publishedYear,
    required int stock,
    String? imagePath,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/books'));
    request.headers.addAll(_authOnlyHeaders(token));
    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['published_year'] = publishedYear.toString();
    request.fields['stock'] = stock.toString();

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return;
    }

    final message = _extractMessage(response, 'Gagal menambahkan buku');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> updateBook({
    required int id,
    required String title,
    required String author,
    required int publishedYear,
    required int stock,
    String? imagePath,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/books/$id'));
    request.headers.addAll(_authOnlyHeaders(token));
    request.fields['title'] = title;
    request.fields['author'] = author;
    request.fields['published_year'] = publishedYear.toString();
    request.fields['stock'] = stock.toString();

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal memperbarui buku');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> deleteBook(int bookId) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal menghapus buku');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> borrowBook(int bookId) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/borrowings'),
      headers: _authHeaders(token),
      body: jsonEncode({'book_id': bookId}),
    );

    if (response.statusCode == 201) {
      return;
    }

    final message = _extractMessage(response, 'Gagal meminjam buku');

    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> returnBorrowing(int borrowingId) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/borrowings/$borrowingId/return'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal mengembalikan buku');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> deleteBorrowing(int borrowingId) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/borrowings/$borrowingId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal menghapus riwayat peminjaman');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<List<Borrowing>> fetchBorrowings() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/borrowings'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Borrowing.fromJson(data)).toList();
    } else {
      final message = _extractMessage(response, 'Gagal mengambil data riwayat peminjaman');
      throw Exception('HTTP ${response.statusCode}: $message');
    }
  }

  Future<List<User>> fetchUsers() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => User.fromJson(data)).toList();
    } else {
      final message = _extractMessage(response, 'Gagal mengambil data pengguna');
      throw Exception('HTTP ${response.statusCode}: $message');
    }
  }

  Future<void> createMember({
    required String name,
    required String email,
    required String password,
  }) async {
    await register(name: name, email: email, password: password);
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal memperbarui anggota');
    throw Exception('HTTP ${response.statusCode}: $message');
  }

  Future<void> deleteUser(int userId) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractMessage(response, 'Gagal menghapus anggota');
    throw Exception('HTTP ${response.statusCode}: $message');
  }
}