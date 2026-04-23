import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../services/api_service.dart';
import '../widgets/catalog/catalog_book_tiles.dart';
import '../widgets/common/loading_skeletons.dart';
import '../widgets/common/state_feedback.dart';
import 'book_detail_screen.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final ApiService _apiService = ApiService();

  Widget _buildCoverPlaceholder({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBookDetail(Book book) async {
    final didBorrow = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );

    if (didBorrow == true && mounted) {
      await Provider.of<BookProvider>(context, listen: false).loadBooks();
    }
  }

  Future<void> _showBookFormDialog({Book? book}) async {
    final isEdit = book != null;
    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final yearController = TextEditingController(text: book?.publishedYear.toString() ?? '');
    final stockController = TextEditingController(text: book?.stock.toString() ?? '1');
    final imagePicker = ImagePicker();
    XFile? selectedImage;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              final year = int.tryParse(yearController.text.trim());
              final stock = int.tryParse(stockController.text.trim());

              if (title.isEmpty || author.isEmpty || year == null || stock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field wajib diisi dengan valid.')),
                );
                return;
              }

              if (year <= 0 || stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tahun harus > 0 dan stok tidak boleh negatif.')),
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              try {
                if (isEdit) {
                  await _apiService.updateBook(
                    id: book.id,
                    title: title,
                    author: author,
                    publishedYear: year,
                    stock: stock,
                    imagePath: selectedImage?.path,
                  );
                } else {
                  await _apiService.addBook(
                    title: title,
                    author: author,
                    publishedYear: year,
                    stock: stock,
                    imagePath: selectedImage?.path,
                  );
                }

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await Provider.of<BookProvider>(this.context, listen: false).loadBooks();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Buku berhasil diperbarui' : 'Buku berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text(isEdit ? 'Edit Buku' : 'Tambah Buku'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Judul Buku'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(labelText: 'Penulis'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tahun Terbit'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final image = await imagePicker.pickImage(source: ImageSource.gallery);
                                if (image == null) return;
                                setDialogState(() {
                                  selectedImage = image;
                                });
                              },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          selectedImage == null
                              ? (isEdit ? 'Ganti Cover (Opsional)' : 'Pilih Cover (Opsional)')
                              : 'Cover dipilih: ${selectedImage!.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isEdit && selectedImage == null && (book.image?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cover saat ini tetap digunakan jika tidak memilih gambar baru.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Yakin ingin menghapus "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteBook(book.id);
      if (!mounted) return;
      await Provider.of<BookProvider>(context, listen: false).loadBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookCover(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _buildCoverPlaceholder(
        icon: Icons.menu_book,
        iconColor: Colors.blue,
        label: 'Tanpa cover',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCoverPlaceholder(
          icon: Icons.photo,
          iconColor: Colors.grey,
          label: 'Memuat cover...',
        ),
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverPlaceholder(
                  icon: Icons.photo,
                  iconColor: Colors.grey,
                  label: 'Memuat cover...',
                ),
                Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildCoverPlaceholder(
              icon: Icons.broken_image,
              iconColor: Colors.redAccent,
              label: 'Gagal memuat',
            );
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;

    if (bookProvider.isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 6,
        itemBuilder: (_, index) => const BookGridSkeletonCard(),
      );
    }

    if (bookProvider.errorMessage != null) {
      return StateFeedback(
        icon: Icons.cloud_off_rounded,
        iconColor: Colors.red.shade400,
        message: 'Gagal memuat buku:\n${bookProvider.errorMessage}',
        actionLabel: 'Coba Lagi',
        onAction: () => bookProvider.loadBooks(),
      );
    }

    if (bookProvider.books.isEmpty) {
      return StateFeedback(
        icon: Icons.library_books_outlined,
        iconColor: Colors.blueGrey.shade300,
        message: 'Belum ada buku di perpustakaan.',
        footer: isAdmin
            ? FilledButton.icon(
                onPressed: _showBookFormDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Buku'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => bookProvider.loadBooks(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: isAdmin ? bookProvider.books.length + 1 : bookProvider.books.length,
        itemBuilder: (context, index) {
          if (isAdmin && index == 0) {
            return AddBookTile(onTap: _showBookFormDialog);
          }

          final dataIndex = isAdmin ? index - 1 : index;
          final book = bookProvider.books[dataIndex];

          return CatalogBookTile(
            book: book,
            isAdmin: isAdmin,
            cover: _buildBookCover(book.image),
            onOpenDetail: () => _openBookDetail(book),
            onEdit: () => _showBookFormDialog(book: book),
            onDelete: () => _deleteBook(book),
          );
        },
      ),
    );
  }
}
