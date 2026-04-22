class Book {
  final int id;
  final String title;
  final String author;
  final int publishedYear;
  final int stock;
  final String? image;
  final DateTime? createdAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publishedYear,
    required this.stock,
    this.image,
    this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      publishedYear: json['published_year'],
      stock: json['stock'],
      image: json['image'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null, 
    );
  }
}