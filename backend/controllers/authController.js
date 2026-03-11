const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

// Array sementara untuk menyimpan refresh token (Pada production nyata, gunakan Database/Redis)
let refreshTokens = [];

// --- Logika Register ---
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

// --- Logika Login ---
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

      // 3. Generate JWT Access Token dan Refresh Token (Sekarang menyertakan role)
        const accessToken = jwt.sign(
            { id: user.id, email: user.email, role: user.role }, // <-- Tambahkan role di sini
            process.env.JWT_SECRET, 
            { expiresIn: '15m' } 
        );
        
        const refreshToken = jwt.sign(
            { id: user.id, email: user.email, role: user.role }, // <-- Tambahkan role di sini
            process.env.JWT_SECRET, 
            { expiresIn: '7d' } 
        );

        // Simpan refresh token
        refreshTokens.push(refreshToken);

        res.status(200).json({ 
            message: 'Login berhasil!',
            user: { id: user.id, name: user.name, email: user.email, role: user.role }, // <-- Kembalikan role ke frontend
            accessToken,
            refreshToken
        });
    } catch (error) {
        res.status(500).json({ message: 'Terjadi kesalahan pada server', error: error.message });
    }
};

// --- Logika Refresh Token ---
const refresh = (req, res) => {
    // Ambil refresh token dari body request
    const { token } = req.body;

    if (!token) return res.status(401).json({ message: 'Refresh token tidak diberikan!' });
    if (!refreshTokens.includes(token)) return res.status(403).json({ message: 'Refresh token tidak valid!' });

    // Verifikasi refresh token
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: 'Token kadaluarsa atau tidak valid!' });

        // Jika valid, buat access token baru
        const newAccessToken = jwt.sign(
            { id: user.id, email: user.email }, 
            process.env.JWT_SECRET, 
            { expiresIn: '15m' }
        );

        res.json({ accessToken: newAccessToken });
    });
};

// --- Logika Logout ---
const logout = (req, res) => {
    const { token } = req.body;
    
    // Hapus token dari array
    refreshTokens = refreshTokens.filter(t => t !== token);
    
    res.status(200).json({ message: 'Logout berhasil!' });
};

module.exports = { register, login, refresh, logout };