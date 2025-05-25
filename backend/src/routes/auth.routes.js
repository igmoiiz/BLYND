const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const User = require('../models/user.model');
const { protect, generateToken } = require('../middleware/auth.middleware');
const supabaseService = require('../services/supabase.service');

const router = express.Router();
const upload = multer();

// Validation middleware
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('phone').isNumeric().withMessage('Phone must be a number'),
  body('userName').trim().notEmpty().withMessage('Username is required'),
  body('age').isNumeric().withMessage('Age must be a number')
];

// Register user
router.post('/register', 
  upload.single('profileImage'),
  registerValidation,
  async (req, res) => {
    try {
      const { name, email, password, phone, userName, age } = req.body;

      // Check if user already exists
      const existingUser = await User.findOne({ 
        $or: [{ email }, { userName }] 
      });

      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Email or username already exists'
        });
      }

      let profileImageUrl = '';
      
      // Upload profile image if provided
      if (req.file) {
        await supabaseService.ensureBucketExists(process.env.SUPABASE_USER_BUCKET);
        profileImageUrl = await supabaseService.uploadUserImage(req.file, userName);
      }

      // Create user
      const user = await User.create({
        name,
        email,
        password,
        phone: parseInt(phone),
        userName,
        age: parseInt(age),
        profileImage: profileImageUrl
      });

      // Generate token
      const token = generateToken(user._id);

      res.status(201).json({
        success: true,
        token,
        user: user.toPublicProfile()
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Error in user registration'
      });
    }
  }
);

// Login user
router.post('/login',
  [
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('password').notEmpty().withMessage('Password is required')
  ],
  async (req, res) => {
    try {
      const { email, password } = req.body;

      // Find user and include password for comparison
      const user = await User.findOne({ email }).select('+password');

      if (!user || !(await user.comparePassword(password))) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }

      // Generate token
      const token = generateToken(user._id);

      res.json({
        success: true,
        token,
        user: user.toPublicProfile()
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Error in user login'
      });
    }
  }
);

// Get current user
router.get('/me', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select('-password')
      .lean();

    res.json({
      success: true,
      user
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user data'
    });
  }
});

// Logout user (optional, as JWT is stateless)
router.post('/logout', protect, (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

module.exports = router; 