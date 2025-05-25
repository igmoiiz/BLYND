const express = require('express');
const multer = require('multer');
const { protect } = require('../middleware/auth.middleware');
const Post = require('../models/post.model');
const User = require('../models/user.model');
const supabaseService = require('../services/supabase.service');

const router = express.Router();
const upload = multer();

// Create a new post
router.post('/',
  protect,
  upload.single('postImage'),
  async (req, res) => {
    try {
      const { caption } = req.body;

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Please provide an image'
        });
      }

      if (!caption) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a caption'
        });
      }

      // Upload image to Supabase
      await supabaseService.ensureBucketExists(process.env.SUPABASE_POST_BUCKET);
      const imageUrl = await supabaseService.uploadPostImage(req.file, req.user._id);

      // Create post
      const post = await Post.create({
        userId: req.user._id,
        userEmail: req.user.email,
        userName: req.user.name,
        userProfileImage: req.user.profileImage,
        caption,
        postImage: imageUrl,
        likeCount: 0,
        likedBy: [],
        comments: []
      });

      res.status(201).json({
        success: true,
        post
      });
    } catch (error) {
      console.error('Create post error:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating post'
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
      .limit(limit)
      .lean();

    const total = await Post.countDocuments();

    res.json({
      success: true,
      posts,
      pagination: {
        current: page,
        pages: Math.ceil(total / limit),
        total
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
      .sort({ createdAt: -1 })
      .lean();

    res.json({
      success: true,
      posts
    });
  } catch (error) {
    console.error('Get user posts error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user posts'
    });
  }
});

// Like/Unlike a post
router.post('/:postId/like', protect, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    const isLiked = post.likedBy.includes(req.user._id);

    if (isLiked) {
      // Unlike
      await Post.findByIdAndUpdate(post._id, {
        $pull: { likedBy: req.user._id },
        $inc: { likeCount: -1 }
      });
    } else {
      // Like
      await Post.findByIdAndUpdate(post._id, {
        $push: { likedBy: req.user._id },
        $inc: { likeCount: 1 }
      });
    }

    res.json({
      success: true,
      message: isLiked ? 'Post unliked' : 'Post liked'
    });
  } catch (error) {
    console.error('Like/Unlike post error:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing like/unlike'
    });
  }
});

// Add comment to a post
router.post('/:postId/comment', protect, async (req, res) => {
  try {
    const { comment } = req.body;

    if (!comment) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a comment'
      });
    }

    const post = await Post.findById(req.params.postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    const newComment = {
      userId: req.user._id,
      userName: req.user.name,
      userProfileImage: req.user.profileImage,
      comment,
      createdAt: new Date()
    };

    await Post.findByIdAndUpdate(post._id, {
      $push: { comments: newComment }
    });

    res.json({
      success: true,
      comment: newComment
    });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding comment'
    });
  }
});

// Delete a post
router.delete('/:postId', protect, async (req, res) => {
  try {
    const post = await Post.findById(req.params.postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Check if user owns the post
    if (post.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this post'
      });
    }

    // Delete image from Supabase
    const fileName = post.postImage.split('/').pop();
    await supabaseService.deleteImage(process.env.SUPABASE_POST_BUCKET, fileName);

    // Delete post from database
    await Post.findByIdAndDelete(post._id);

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

// Get feed posts (posts from followed users)
router.get('/feed', protect, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const user = await User.findById(req.user._id);
    const following = user.following;

    // Get posts from followed users and own posts
    const posts = await Post.find({
      $or: [
        { userId: { $in: following } },
        { userId: req.user._id }
      ]
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Post.countDocuments({
      $or: [
        { userId: { $in: following } },
        { userId: req.user._id }
      ]
    });

    res.json({
      success: true,
      posts,
      pagination: {
        current: page,
        pages: Math.ceil(total / limit),
        total
      }
    });
  } catch (error) {
    console.error('Get feed error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching feed'
    });
  }
});

module.exports = router; 