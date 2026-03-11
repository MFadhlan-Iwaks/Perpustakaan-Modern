const User = require('../models/userModel');

const getUsers = async (req, res) => {
    try {
        const users = await User.getAllUsers();
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const updateUserInfo = async (req, res) => {
    try {
        const { name, email, role } = req.body;
        const affectedRows = await User.updateUser(req.params.id, name, email, role);
        
        if (affectedRows === 0) return res.status(404).json({ message: 'User tidak ditemukan' });
        res.status(200).json({ message: 'Data user berhasil diperbarui' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

const removeUser = async (req, res) => {
    try {
        const affectedRows = await User.deleteUser(req.params.id);
        
        if (affectedRows === 0) return res.status(404).json({ message: 'User tidak ditemukan' });
        res.status(200).json({ message: 'User berhasil dihapus' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
    }
};

module.exports = { getUsers, updateUserInfo, removeUser };