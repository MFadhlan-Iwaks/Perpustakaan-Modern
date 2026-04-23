import 'package:flutter/material.dart';

class BookCoverPanel extends StatelessWidget {
  final String? imageUrl;

  const BookCoverPanel({super.key, required this.imageUrl});

  Widget _placeholder({required IconData icon, required Color iconColor, required String label}) {
    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: iconColor),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl;

    if (resolvedImageUrl == null || resolvedImageUrl.trim().isEmpty) {
      return _placeholder(
        icon: Icons.menu_book,
        iconColor: Colors.blue,
        label: 'Tidak ada cover tersedia',
      );
    }

    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Image.network(
        resolvedImageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return _placeholder(
            icon: Icons.broken_image,
            iconColor: Colors.redAccent,
            label: 'Cover gagal dimuat',
          );
        },
      ),
    );
  }
}

class BookDetailInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const BookDetailInfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
