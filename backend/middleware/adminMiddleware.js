const authorizeAdmin = (req, res, next) => {

    if (!req.user) {
        return res.status(401).json({ message: 'Akses ditolak! Anda belum login.' });
    }

    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({ message: 'Akses ditolak! Tindakan ini hanya untuk Petugas.' });
    }

    next();
};

module.exports = authorizeAdmin;