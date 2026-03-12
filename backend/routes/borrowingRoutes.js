const express = require('express');
const router = express.Router();
const borrowingController = require('../controllers/borrowingController');
const authenticateToken = require('../middleware/authMiddleware');
const authorizeAdmin = require('../middleware/adminMiddleware');

router.use(authenticateToken);

router.get('/borrowings', borrowingController.getBorrowings);
router.post('/borrowings', borrowingController.createBorrowing);
router.put('/borrowings/:id/return', borrowingController.returnBook);
router.delete('/borrowings/:id', authorizeAdmin, borrowingController.removeBorrowing);

module.exports = router;