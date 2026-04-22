import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrowing_model.dart';
import '../providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';
import '../services/api_service.dart';

class BorrowingScreen extends StatefulWidget {
  const BorrowingScreen({super.key});

  @override
  State<BorrowingScreen> createState() => _BorrowingScreenState();
}

class _BorrowingScreenState extends State<BorrowingScreen> {
  final ApiService _apiService = ApiService();
  final Set<int> _returningIds = <int>{};
  final Set<int> _deletingIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BorrowingProvider>(context, listen: false).loadBorrowings();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RETURNED':
        return Colors.green;
      case 'BORROWED':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _handleReturn(Borrowing borrowing) async {
    final shouldReturn = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Text('Kembalikan buku "${borrowing.bookTitle ?? '-'}" sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );

    if (shouldReturn != true) return;

    setState(() {
      _returningIds.add(borrowing.id);
    });

    try {
      await _apiService.returnBorrowing(borrowing.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status peminjaman berhasil diubah ke Dikembalikan'),
          backgroundColor: Colors.green,
        ),
      );

      await Provider.of<BorrowingProvider>(context, listen: false).loadBorrowings();
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
          _returningIds.remove(borrowing.id);
        });
      }
    }
  }

  Future<void> _handleDelete(Borrowing borrowing) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: Text('Hapus riwayat peminjaman untuk buku "${borrowing.bookTitle ?? '-'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _deletingIds.add(borrowing.id);
    });

    try {
      await _apiService.deleteBorrowing(borrowing.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat peminjaman berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      await Provider.of<BorrowingProvider>(context, listen: false).loadBorrowings();
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
          _deletingIds.remove(borrowing.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowingProvider = Provider.of<BorrowingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    if (borrowingProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (borrowingProvider.errorMessage != null) {
      return Center(
        child: Text(
          'Gagal memuat riwayat:\n${borrowingProvider.errorMessage}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (borrowingProvider.borrowings.isEmpty) {
      return Center(
        child: Text(
          isAdmin
              ? 'Belum ada data transaksi peminjaman.'
              : 'Belum ada riwayat peminjaman.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => borrowingProvider.loadBorrowings(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: borrowingProvider.borrowings.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final borrowing = borrowingProvider.borrowings[index];
          return _BorrowingCard(
            borrowing: borrowing,
            isAdmin: isAdmin,
            statusColor: _statusColor(borrowing.status),
            borrowDate: _formatDate(borrowing.borrowDate),
            returnDate: _formatDate(borrowing.returnDate),
            isReturning: _returningIds.contains(borrowing.id),
            isDeleting: _deletingIds.contains(borrowing.id),
            onReturn: () => _handleReturn(borrowing),
            onDelete: () => _handleDelete(borrowing),
          );
        },
      ),
    );
  }
}

class _BorrowingCard extends StatelessWidget {
  final Borrowing borrowing;
  final bool isAdmin;
  final Color statusColor;
  final String borrowDate;
  final String returnDate;
  final bool isReturning;
  final bool isDeleting;
  final VoidCallback onReturn;
  final VoidCallback onDelete;

  const _BorrowingCard({
    required this.borrowing,
    required this.isAdmin,
    required this.statusColor,
    required this.borrowDate,
    required this.returnDate,
    required this.isReturning,
    required this.isDeleting,
    required this.onReturn,
    required this.onDelete,
  });

  String _statusLabel(String status) {
    return status.toUpperCase() == 'RETURNED' ? 'Dikembalikan' : 'Dipinjam';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.history, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.bookTitle ?? 'Judul tidak tersedia',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? 'Peminjam: ${borrowing.userName ?? '-'}'
                            : 'Riwayat peminjaman Anda',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(borrowing.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Tanggal Pinjam', borrowDate),
            const SizedBox(height: 8),
            _detailRow('Tanggal Kembali', returnDate),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: isAdmin
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (borrowing.status.toUpperCase() == 'RETURNED')
                          const Text(
                            'Sudah dikembalikan',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          )
                        else
                          TextButton.icon(
                            onPressed: (isReturning || isDeleting) ? null : onReturn,
                            icon: isReturning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.assignment_returned_outlined),
                            label: Text(isReturning ? 'Memproses...' : 'Kembalikan'),
                          ),
                        TextButton.icon(
                          onPressed: (isReturning || isDeleting) ? null : onDelete,
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                          label: Text(isDeleting ? 'Menghapus...' : 'Hapus'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    )
                  : borrowing.status.toUpperCase() == 'RETURNED'
                      ? const Text(
                          'Sudah dikembalikan',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        )
                      : const Text(
                          'Menunggu verifikasi Admin',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}