const Borrowing = require('../models/borrowingModel');

const getBorrowings = async (req, res) => {
    try {
        let borrowings;

        if (req.user.role === 'ADMIN') {
            borrowings = await Borrowing.getAllBorrowings();
        } else {
            borrowings = await Borrowing.getUserBorrowings(req.user.id);
        }
        res.status(200).json(borrowings);
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const createBorrowing = async (req, res) => {
    try {
        const { book_id } = req.body;
        const user_id = req.user.id;
        
        if (!book_id) return res.status(400).json({ message: 'ID Buku wajib diisi' });

        await Borrowing.borrowBook(user_id, book_id);
        res.status(201).json({ message: 'Buku berhasil dipinjam' });
    } catch (error) {
        
        if (error.message === 'Stok buku habis' || error.message === 'Buku tidak ditemukan') {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const returnBook = async (req, res) => {
    try {
        const borrowingId = req.params.id;

        await Borrowing.returnBook(borrowingId);
        res.status(200).json({ message: 'Buku berhasil dikembalikan' });
    } catch (error) {
        if (error.message === 'Data peminjaman tidak ditemukan' || error.message === 'Buku sudah dikembalikan sebelumnya') {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const removeBorrowing = async (req, res) => {
    try {
        const affectedRows = await Borrowing.deleteBorrowing(req.params.id);
        if (affectedRows === 0) return res.status(404).json({ message: 'Data peminjaman tidak ditemukan' });
        
        res.status(200).json({ message: 'Riwayat peminjaman berhasil dihapus' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

module.exports = { getBorrowings, createBorrowing, returnBook, removeBorrowing };