const db = require('../config/db');

// Mengambil semua riwayat peminjaman beserta nama user dan judul buku (JOIN)
const getAllBorrowings = async () => {
    const query = `
        SELECT br.id, u.name AS user_name, b.title AS book_title, 
               br.borrow_date, br.return_date, br.status 
        FROM borrowings br
        JOIN users u ON br.user_id = u.id
        JOIN books b ON br.book_id = b.id
        ORDER BY br.borrow_date DESC
    `;
    const [rows] = await db.query(query);
    return rows;
};

// Logika meminjam buku (Pakai Transaction agar aman)
const borrowBook = async (userId, bookId) => {
    const connection = await db.getConnection(); // Ambil koneksi manual
    try {
        await connection.beginTransaction(); // Mulai transaksi

        // 1. Cek stok buku terlebih dahulu
        const [books] = await connection.query('SELECT stock FROM books WHERE id = ? FOR UPDATE', [bookId]);
        if (books.length === 0) throw new Error('Buku tidak ditemukan');
        if (books[0].stock < 1) throw new Error('Stok buku habis');

        // 2. Catat ke tabel borrowings
        const borrowDate = new Date().toISOString().split('T')[0]; // Format YYYY-MM-DD
        await connection.query(
            'INSERT INTO borrowings (user_id, book_id, borrow_date) VALUES (?, ?, ?)',
            [userId, bookId, borrowDate]
        );

        // 3. Kurangi stok buku
        await connection.query('UPDATE books SET stock = stock - 1 WHERE id = ?', [bookId]);

        await connection.commit(); // Simpan permanen perubahan
        return true;
    } catch (error) {
        await connection.rollback(); // Batalkan semua jika ada error
        throw error;
    } finally {
        connection.release(); // Kembalikan koneksi ke pool
    }
};

// Logika mengembalikan buku
const returnBook = async (borrowingId) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Cek data peminjaman
        const [borrowings] = await connection.query('SELECT book_id, status FROM borrowings WHERE id = ? FOR UPDATE', [borrowingId]);
        if (borrowings.length === 0) throw new Error('Data peminjaman tidak ditemukan');
        if (borrowings[0].status === 'RETURNED') throw new Error('Buku sudah dikembalikan sebelumnya');

        const bookId = borrowings[0].book_id;

        // 2. Update status jadi RETURNED
        const returnDate = new Date().toISOString().split('T')[0];
        await connection.query(
            'UPDATE borrowings SET status = "RETURNED", return_date = ? WHERE id = ?',
            [returnDate, borrowingId]
        );

        // 3. Tambahkan kembali stok buku
        await connection.query('UPDATE books SET stock = stock + 1 WHERE id = ?', [bookId]);

        await connection.commit();
        return true;
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
};

// Mengambil riwayat peminjaman khusus untuk 1 user
const getUserBorrowings = async (userId) => {
    const query = `
        SELECT br.id, b.title AS book_title, br.borrow_date, br.return_date, br.status 
        FROM borrowings br
        JOIN books b ON br.book_id = b.id
        WHERE br.user_id = ?
        ORDER BY br.borrow_date DESC
    `;
    const [rows] = await db.query(query, [userId]);
    return rows;
};

// Admin bisa menghapus riwayat
const deleteBorrowing = async (id) => {
    const [result] = await db.query('DELETE FROM borrowings WHERE id = ?', [id]);
    return result.affectedRows;
};

module.exports = { getAllBorrowings, borrowBook, returnBook, getUserBorrowings, deleteBorrowing };