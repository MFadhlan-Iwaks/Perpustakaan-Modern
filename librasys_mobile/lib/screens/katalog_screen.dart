import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../services/api_service.dart';
import 'book_detail_screen.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final ApiService _apiService = ApiService();

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(color: const Color(0xFFE2E8F0)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: double.infinity, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                Container(height: 10, width: 90, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                Container(height: 30, width: double.infinity, color: const Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildAddBookCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showBookFormDialog(),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.tertiary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_box_rounded, size: 44, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                'Tambah Buku',
                style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

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
        itemBuilder: (_, index) => _buildSkeletonCard(),
      );
    }

    if (bookProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 52, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat buku:\n${bookProvider.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => bookProvider.loadBooks(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (bookProvider.books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.library_books_outlined, size: 56, color: Colors.blueGrey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Belum ada buku di perpustakaan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _showBookFormDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Buku'),
                ),
              ],
            ],
          ),
        ),
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
            return _buildAddBookCard();
          }

          final dataIndex = isAdmin ? index - 1 : index;
          final book = bookProvider.books[dataIndex];

          return InkWell(
            onTap: () => _openBookDetail(book),
            child: Card(
              elevation: 1.8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildBookCover(book.image),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stok: ${book.stock}',
                          style: TextStyle(
                            color: book.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showBookFormDialog(book: book),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.6)),
                                    foregroundColor: colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _deleteBook(book),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openBookDetail(book),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Pinjam',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
