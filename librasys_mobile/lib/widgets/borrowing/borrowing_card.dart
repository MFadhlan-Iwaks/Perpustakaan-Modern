import 'package:flutter/material.dart';

import '../../models/borrowing_model.dart';

class BorrowingCard extends StatelessWidget {
  final Borrowing borrowing;
  final bool isAdmin;
  final Color statusColor;
  final String borrowDate;
  final String returnDate;
  final bool isReturning;
  final bool isDeleting;
  final VoidCallback onReturn;
  final VoidCallback onDelete;

  const BorrowingCard({
    super.key,
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
      elevation: 1.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.history_rounded, color: statusColor),
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
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin ? 'Peminjam: ${borrowing.userName ?? '-'}' : 'Riwayat peminjaman Anda',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
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
                      fontWeight: FontWeight.w700,
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
                            style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600),
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
                          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                        ),
                      ],
                    )
                  : borrowing.status.toUpperCase() == 'RETURNED'
                      ? const Text(
                          'Sudah dikembalikan',
                          style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        )
                      : const Text(
                          'Menunggu verifikasi Admin',
                          style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
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
