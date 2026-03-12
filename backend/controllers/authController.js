const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

let refreshTokens = [];

const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;
        
        const existingUser = await User.getUserByEmail(email);
        if (existingUser) {
            return res.status(400).json({ message: 'Email sudah terdaftar!' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        await User.createUser(name, email, hashedPassword);

        res.status(201).json({ message: 'Registrasi berhasil! Silakan login.' });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan pada server', error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.getUserByEmail(email);
        if (!user) {
            return res.status(404).json({ message: 'Email tidak ditemukan!' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Password salah!' });
        }

        const accessToken = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET, 
            { expiresIn: '15m' } 
        );
        
        const refreshToken = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET, 
            { expiresIn: '7d' } 
        );

        refreshTokens.push(refreshToken);

        res.status(200).json({ 
            message: 'Login berhasil!',
            user: { id: user.id, name: user.name, email: user.email, role: user.role },
            accessToken,
            refreshToken
        });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan pada server', error: error.message });
    }
};

const refresh = (req, res) => {

    const { token } = req.body;

    if (!token) return res.status(401).json({ message: 'Refresh token tidak diberikan!' });
    if (!refreshTokens.includes(token)) return res.status(403).json({ message: 'Refresh token tidak valid!' });

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: 'Token kadaluarsa atau tidak valid!' });

        const newAccessToken = jwt.sign(
            { id: user.id, email: user.email }, 
            process.env.JWT_SECRET, 
            { expiresIn: '15m' }
        );

        res.json({ accessToken: newAccessToken });
    });
};

const logout = (req, res) => {
    const { token } = req.body;

    refreshTokens = refreshTokens.filter(t => t !== token);
    
    res.status(200).json({ message: 'Logout berhasil!' });
};

module.exports = { register, login, refresh, logout };