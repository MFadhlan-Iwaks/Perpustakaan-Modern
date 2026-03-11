const jwt = require('jsonwebtoken');
require('dotenv').config();

const authenticateToken = (req, res, next) => {
    // 1. Ambil token dari header Authorization
    const authHeader = req.headers['authorization'];
    
    // Format header biasanya: "Bearer <token>"
    // Kita split berdasarkan spasi dan ambil index ke-1 (tokennya saja)
    const token = authHeader && authHeader.split(' ')[1];

    // 2. Jika tidak ada token, tolak akses (401 Unauthorized)
    if (!token) {
        return res.status(401).json({ message: 'Akses ditolak! Token tidak ditemukan.' });
    }

    // 3. Verifikasi token menggunakan JWT_SECRET
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            // Jika token salah atau sudah expired, tolak akses (403 Forbidden)
            return res.status(403).json({ message: 'Akses ditolak! Token tidak valid atau sudah kadaluarsa.' });
        }
        
        // 4. Jika valid, simpan data payload user ke object request (req.user)
        // Agar data user yang sedang login bisa diakses oleh controller selanjutnya
        req.user = user;
        
        // Lanjut ke proses berikutnya (controller)
        next();
    });
};

module.exports = authenticateToken;