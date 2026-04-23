import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isBorrowing = false;

  Widget _buildCover() {
    final imageUrl = widget.book.image;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 72, color: Colors.blue),
            SizedBox(height: 12),
            Text('Tidak ada cover tersedia'),
          ],
        ),
      );
    }

    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 72, color: Colors.redAccent),
              SizedBox(height: 12),
              Text('Cover gagal dimuat'),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleBorrow() async {
    setState(() {
      _isBorrowing = true;
    });

    try {
      await _apiService.borrowBook(widget.book.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil dipinjam'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBorrowing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Buku'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.author,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  _infoTile('Tahun Terbit', widget.book.publishedYear.toString()),
                  _infoTile('Stok', widget.book.stock.toString()),
                  const SizedBox(height: 24),
                  if (!isAdmin)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isBorrowing ? null : _handleBorrow,
                        icon: _isBorrowing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.shopping_bag_outlined),
                        label: Text(_isBorrowing ? 'Meminjam...' : 'Pinjam Buku'),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Color(0xFF334155)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode admin: aksi pinjam dinonaktifkan.',
                              style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}