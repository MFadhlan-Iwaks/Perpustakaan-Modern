class Borrowing {
  final int id;
  final int? userId;
  final int? bookId;
  final DateTime borrowDate;
  final DateTime? returnDate;
  final String status;
  final DateTime? createdAt;

  final String? bookTitle;
  final String? userName;

  Borrowing({
    required this.id,
    this.userId,
    this.bookId,
    required this.borrowDate,
    this.returnDate,
    required this.status,
    this.createdAt,
    this.bookTitle,
    this.userName,
  });

  factory Borrowing.fromJson(Map<String, dynamic> json) {
    return Borrowing(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      borrowDate: DateTime.parse(json['borrow_date']),
      returnDate: json['return_date'] != null ? DateTime.parse(json['return_date']) : null,
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      bookTitle: json['book_title'],
      userName: json['user_name'],
    );
  }
}