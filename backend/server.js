require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const db = require('./config/db');
const path = require('path');


const authRoutes = require('./routes/authRoutes');
const bookRoutes = require('./routes/bookRoutes');
const borrowingRoutes = require('./routes/borrowingRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

app.use('/api', authRoutes);
app.use('/api', bookRoutes);
app.use('/api', borrowingRoutes);
app.use('/api', userRoutes);

app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ message: 'Ukuran file maksimal 2MB.' });
        }
        return res.status(400).json({ message: `Upload gagal: ${err.message}` });
    }

    if (err && err.message) {
        return res.status(400).json({ message: err.message });
    }

    return next();
});

app.get('/', (req, res) => {
    res.json({ message: 'Selamat datang di API Sistem Manajemen Perpustakaan' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
