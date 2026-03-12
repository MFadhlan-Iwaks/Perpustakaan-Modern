const db = require('../config/db');

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

const borrowBook = async (userId, bookId) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const [books] = await connection.query('SELECT stock FROM books WHERE id = ? FOR UPDATE', [bookId]);
        if (books.length === 0) throw new Error('Buku tidak ditemukan');
        if (books[0].stock < 1) throw new Error('Stok buku habis');

        const borrowDate = new Date().toISOString().split('T')[0];
        await connection.query(
            'INSERT INTO borrowings (user_id, book_id, borrow_date) VALUES (?, ?, ?)',
            [userId, bookId, borrowDate]
        );

        await connection.query('UPDATE books SET stock = stock - 1 WHERE id = ?', [bookId]);

        await connection.commit();
        return true;
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
};

const returnBook = async (borrowingId) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const [borrowings] = await connection.query('SELECT book_id, status FROM borrowings WHERE id = ? FOR UPDATE', [borrowingId]);
        if (borrowings.length === 0) throw new Error('Data peminjaman tidak ditemukan');
        if (borrowings[0].status === 'RETURNED') throw new Error('Buku sudah dikembalikan sebelumnya');

        const bookId = borrowings[0].book_id;

        const returnDate = new Date().toISOString().split('T')[0];
        await connection.query(
            'UPDATE borrowings SET status = "RETURNED", return_date = ? WHERE id = ?',
            [returnDate, borrowingId]
        );

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

const deleteBorrowing = async (id) => {
    const [result] = await db.query('DELETE FROM borrowings WHERE id = ?', [id]);
    return result.affectedRows;
};

module.exports = { getAllBorrowings, borrowBook, returnBook, getUserBorrowings, deleteBorrowing };