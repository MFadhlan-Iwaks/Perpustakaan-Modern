const db = require('../config/db');

const createUser = async (name, email, hashedPassword) => {
    const [result] = await db.query(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [name, email, hashedPassword]
    );
    return result;
};

const getUserByEmail = async (email) => {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0];
};

const getAllUsers = async () => {
    const [rows] = await db.query('SELECT id, name, email, role, created_at FROM users ORDER BY created_at DESC');
    return rows;
};

const updateUser = async (id, name, email, role) => {
    const [result] = await db.query(
        'UPDATE users SET name = ?, email = ?, role = ? WHERE id = ?',
        [name, email, role, id]
    );
    return result.affectedRows;
};

const deleteUser = async (id) => {
    const [result] = await db.query('DELETE FROM users WHERE id = ?', [id]);
    return result.affectedRows;
};

module.exports = { createUser, getUserByEmail, getAllUsers, updateUser, deleteUser };