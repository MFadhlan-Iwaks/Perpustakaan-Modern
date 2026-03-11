const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authenticateToken = require('../middleware/authMiddleware');
const authorizeAdmin = require('../middleware/adminMiddleware'); // Wajib Admin

router.use(authenticateToken);
router.use(authorizeAdmin); // Berlaku untuk semua route di bawahnya

router.get('/users', userController.getUsers);
router.put('/users/:id', userController.updateUserInfo);
router.delete('/users/:id', userController.removeUser);

module.exports = router;