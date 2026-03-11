const multer = require('multer');
const path = require('path');

// Konfigurasi penyimpanan multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads/'); // Folder tujuan simpan gambar
    },
    filename: (req, file, cb) => {
        // Format nama file: timestamp-namagambar.ext
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

// Filter khusus hanya untuk gambar
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
        return cb(null, true);
    } else {
        cb(new Error('Hanya diperbolehkan format gambar (jpeg, jpg, png, webp)!'));
    }
};

const upload = multer({ 
    storage: storage, 
    fileFilter: fileFilter,
    limits: { fileSize: 2 * 1024 * 1024 } // Batas ukuran file 2MB
});

module.exports = upload;