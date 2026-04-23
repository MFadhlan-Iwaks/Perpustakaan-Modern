import 'package:flutter/material.dart';

class BookGridSkeletonCard extends StatelessWidget {
  const BookGridSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: ColoredBox(color: Color(0xFFE2E8F0)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(
                  height: 12,
                  width: double.infinity,
                  child: ColoredBox(color: Color(0xFFE2E8F0)),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 10,
                  width: 90,
                  child: ColoredBox(color: Color(0xFFE2E8F0)),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: ColoredBox(color: Color(0xFFE2E8F0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BorrowingListSkeletonCard extends StatelessWidget {
  const BorrowingListSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(
                        height: 12,
                        width: double.infinity,
                        child: ColoredBox(color: Color(0xFFE2E8F0)),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 10,
                        width: 120,
                        child: ColoredBox(color: Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 10,
              width: 180,
              child: ColoredBox(color: Color(0xFFE2E8F0)),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              height: 10,
              width: 160,
              child: ColoredBox(color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
      ),
    );
  }
}
