const db = require('../config/db');

const getAllBooks = async () => {
    const [rows] = await db.query('SELECT * FROM books ORDER BY created_at DESC');
    return rows;
};

const getBookById = async (id) => {
    const [rows] = await db.query('SELECT * FROM books WHERE id = ?', [id]);
    return rows[0];
};

const createBook = async (title, author, published_year, image, stock) => {
    const [result] = await db.query(
        'INSERT INTO books (title, author, published_year, image, stock) VALUES (?, ?, ?, ?, ?)',
        [title, author, published_year, image, stock]
    );
    return result.insertId;
};

const updateBook = async (id, title, author, published_year, image, stock) => {
    
    const [result] = await db.query(
        'UPDATE books SET title = ?, author = ?, published_year = ?, stock = ?, image = COALESCE(?, image) WHERE id = ?',
        [title, author, published_year, stock, image, id]
    );
    return result.affectedRows;
};

const deleteBook = async (id) => {
    const [result] = await db.query('DELETE FROM books WHERE id = ?', [id]);
    return result.affectedRows;
};

module.exports = { getAllBooks, getBookById, createBook, updateBook, deleteBook };