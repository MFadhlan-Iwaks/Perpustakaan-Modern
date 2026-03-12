const Book = require('../models/bookModel');

const getBooks = async (req, res) => {
    try {
        const books = await Book.getAllBooks();
        res.status(200).json(books);
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const getBook = async (req, res) => {
    try {
        const book = await Book.getBookById(req.params.id);
        if (!book) return res.status(404).json({ message: 'Buku tidak ditemukan' });
        
        res.status(200).json(book);
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const addBook = async (req, res) => {
    try {
        const { title, author, published_year, stock } = req.body;

        const image = req.file ? req.file.filename : null; 
        
        if (!title || !author || !published_year) {
            return res.status(400).json({ message: 'Judul, penulis, dan tahun terbit wajib diisi' });
        }

        const insertId = await Book.createBook(title, author, published_year, image, stock || 1);
        res.status(201).json({ message: 'Buku berhasil ditambahkan', id: insertId });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const updateBookInfo = async (req, res) => {
    try {
        const { title, author, published_year, stock } = req.body;

        const image = req.file ? req.file.filename : null; 

        const affectedRows = await Book.updateBook(req.params.id, title, author, published_year, image, stock);
        
        if (affectedRows === 0) return res.status(404).json({ message: 'Buku tidak ditemukan' });
        
        res.status(200).json({ message: 'Buku berhasil diperbarui' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const removeBook = async (req, res) => {
    try {
        const affectedRows = await Book.deleteBook(req.params.id);
        
        if (affectedRows === 0) return res.status(404).json({ message: 'Buku tidak ditemukan' });
        
        res.status(200).json({ message: 'Buku berhasil dihapus' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

module.exports = { getBooks, getBook, addBook, updateBookInfo, removeBook };