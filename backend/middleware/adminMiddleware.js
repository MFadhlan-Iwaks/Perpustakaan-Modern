const authorizeAdmin = (req, res, next) => {
    // Pastikan req.user sudah ada (berarti sudah melewati authMiddleware)
    if (!req.user) {
        return res.status(401).json({ message: 'Akses ditolak! Anda belum login.' });
    }

    // Cek apakah role-nya adalah ADMIN
    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({ message: 'Akses ditolak! Tindakan ini hanya untuk Petugas.' });
    }

    // Jika ADMIN, silakan lanjut
    next();
};

module.exports = authorizeAdmin;