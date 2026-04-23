import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrowing_model.dart';
import '../providers/auth_provider.dart';
import '../providers/borrowing_provider.dart';
import '../services/api_service.dart';
import '../widgets/borrowing/borrowing_card.dart';
import '../widgets/common/loading_skeletons.dart';
import '../widgets/common/state_feedback.dart';

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
        return const Color(0xFF15803D);
      case 'BORROWED':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
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
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (_, index) => const BorrowingListSkeletonCard(),
      );
    }

    if (borrowingProvider.errorMessage != null) {
      return StateFeedback(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade400,
        message: 'Gagal memuat riwayat:\n${borrowingProvider.errorMessage}',
        actionLabel: 'Coba Lagi',
        onAction: () => borrowingProvider.loadBorrowings(),
      );
    }

    if (borrowingProvider.borrowings.isEmpty) {
      return StateFeedback(
        icon: Icons.history_toggle_off_rounded,
        iconColor: Colors.blueGrey.shade300,
        message: isAdmin
            ? 'Belum ada data transaksi peminjaman.'
            : 'Belum ada riwayat peminjaman.',
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
          return BorrowingCard(
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
