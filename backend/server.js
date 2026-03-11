require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./config/db');
const path = require('path'); // <-- Tambahkan di bagian atas file


// Import routes
const authRoutes = require('./routes/authRoutes');
const bookRoutes = require('./routes/bookRoutes');
const borrowingRoutes = require('./routes/borrowingRoutes'); // <-- Tambahkan ini
const userRoutes = require('./routes/userRoutes'); // <-- Tambahkan di bagian import routes

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

// Gunakan routes
app.use('/api', authRoutes);
app.use('/api', bookRoutes);
app.use('/api', borrowingRoutes); // <-- Tambahkan ini
app.use('/api', userRoutes); // <-- Tambahkan di bagian app.use

app.get('/', (req, res) => {
    res.json({ message: 'Selamat datang di API Sistem Manajemen Perpustakaan' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server berjalan di http://localhost:${PORT}`);
});
