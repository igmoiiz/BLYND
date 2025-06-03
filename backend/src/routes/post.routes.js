const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const Post = require('../models/post.model');
const { protect } = require('../middleware/auth.middleware');
const { uploadPostMedia, BUCKET_NAMES } = require('../services/supabase.service');

const router = express.Router();
const upload = multer();

// Create post
router.post('/',
  protect,
  upload.array('media', 10), // Accept up to 10 files
  async (req, res) => {
    try {
      const { caption } = req.body;
      const files = req.files || [];
      const media = [];

      for (const file of files) {
        const url = await uploadPostMedia(file, req.user._id);
        let type = 'image';
        if (file.mimetype.startsWith('video/')) type = 'video';
        media.push({ url, type });
      }

      const post = await Post.create({
        userId: req.user._id,
        userEmail: req.user.email,
        userName: req.user.userName,
        userProfileImage: req.user.profileImage,
        caption,
        media
      });

      res.status(201).json({
        success: true,
        post: post.toClientFormat()
      });
    } catch (error) {
      console.error('Create post error:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating post',
        error: error.message
      });
    }
  }
);

// Get all posts (with pagination)
router.get('/', protect, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Post.countDocuments();

    res.json({
      success: true,
      posts: posts.map(post => post.toClientFormat()),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get posts error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching posts'
    });
  }
});

// Get user's posts
router.get('/user/:userId', protect, async (req, res) => {
  try {
    const posts = await Post.find({ userId: req.params.userId })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      posts: posts.map(post => post.toClientFormat())
    });
  } catch (error) {
    console.error('Get user posts error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user posts'
    });
  }
});

// Like/Unlike post
router.post('/:postId/like', protect, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    const userIndex = post.likedBy.indexOf(req.user._id);
    if (userIndex === -1) {
      // Like post
      post.likedBy.push(req.user._id);
      post.likeCount = post.likedBy.length;
    } else {
      // Unlike post
      post.likedBy.splice(userIndex, 1);
      post.likeCount = post.likedBy.length;
    }

    await post.save();

    res.json({
      success: true,
      post: post.toClientFormat()
    });
  } catch (error) {
    console.error('Like/Unlike post error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating post like'
    });
  }
});

// Add comment
router.post('/:postId/comment',
  protect,
  [
    body('text').trim().notEmpty().withMessage('Comment text is required')
  ],
  async (req, res) => {
    try {
      const { text } = req.body;
      const post = await Post.findById(req.params.postId);

      if (!post) {
        return res.status(404).json({
          success: false,
          message: 'Post not found'
        });
      }

      post.comments.push({
        userId: req.user._id,
        userName: req.user.userName,
        userProfileImage: req.user.profileImage,
        text
      });

      await post.save();

      res.json({
        success: true,
        post: post.toClientFormat()
      });
    } catch (error) {
      console.error('Add comment error:', error);
      res.status(500).json({
        success: false,
        message: 'Error adding comment'
      });
    }
  }
);

// Delete post
router.delete('/:postId', protect, async (req, res) => {
  try {
    const post = await Post.findOne({
      _id: req.params.postId,
      userId: req.user._id
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found or unauthorized'
      });
    }

    await post.remove();

    res.json({
      success: true,
      message: 'Post deleted successfully'
    });
  } catch (error) {
    console.error('Delete post error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting post'
    });
  }
});

module.exports = router; 