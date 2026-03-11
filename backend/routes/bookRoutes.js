const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');
const authenticateToken = require('../middleware/authMiddleware');
const authorizeAdmin = require('../middleware/adminMiddleware');
const upload = require('../middleware/uploadMiddleware'); // <-- Import multer

router.use(authenticateToken);

router.get('/books', bookController.getBooks);
router.get('/books/:id', bookController.getBook);

// Pasang middleware upload.single('image') sebelum fungsi controller
router.post('/books', authorizeAdmin, upload.single('image'), bookController.addBook);
router.put('/books/:id', authorizeAdmin, upload.single('image'), bookController.updateBookInfo);
router.delete('/books/:id', authorizeAdmin, bookController.removeBook);

module.exports = router;