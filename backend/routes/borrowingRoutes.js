const express = require('express');
const router = express.Router();
const borrowingController = require('../controllers/borrowingController');
const authenticateToken = require('../middleware/authMiddleware'); // Wajib login
const authorizeAdmin = require('../middleware/adminMiddleware'); // Tambahkan di atas

router.use(authenticateToken); // Lindungi semua endpoint di bawahnya

// Endpoint Transaksi Peminjaman
router.get('/borrowings', borrowingController.getBorrowings);
router.post('/borrowings', borrowingController.createBorrowing);
router.put('/borrowings/:id/return', borrowingController.returnBook);
router.delete('/borrowings/:id', authorizeAdmin, borrowingController.removeBorrowing);

module.exports = router;