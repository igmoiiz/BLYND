const express = require('express');
const multer = require('multer');
const { protect } = require('../middleware/auth.middleware');
const User = require('../models/user.model');
const Post = require('../models/post.model');
const supabaseService = require('../services/supabase.service');

const router = express.Router();
const upload = multer();

// Search users by username or name
router.get('/', protect, async (req, res) => {
  try {
    const search = req.query.search;
    let users = [];
    if (search && search.trim() !== '') {
      users = await User.find({
        $or: [
          { userName: { $regex: search, $options: 'i' } },
          { name: { $regex: search, $options: 'i' } }
        ]
      })
        .select('-password')
        .limit(20);
    } else {
      // Optionally, return trending/recent users or empty array
      users = [];
    }
    res.json({
      success: true,
      users: users.map(u => u.toPublicProfile ? u.toPublicProfile() : u)
    });
  } catch (error) {
    console.error('User search error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching users'
    });
  }
});

// Get user profile
router.get('/:userId', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select('-password')
      .lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get followers and following count
    const followersCount = await User.countDocuments({
      following: user._id
    });

    const followingCount = await User.countDocuments({
      followers: user._id
    });

    // Get posts count
    const postsCount = await Post.countDocuments({
      userId: user._id
    });

    // Check if the requesting user is following this user
    const isFollowing = req.user.following.includes(user._id);

    res.json({
      success: true,
      user: {
        ...user,
        followersCount,
        followingCount,
        postsCount,
        isFollowing
      }
    });
  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user profile'
    });
  }
});

// Update user profile
router.put('/profile', 
  protect,
  async (req, res) => {
    try {
      const { name, bio, profileImage } = req.body;
      const updates = {};

      if (name) updates.name = name;
      if (bio) updates.bio = bio;
      if (profileImage) updates.profileImage = profileImage;

      const user = await User.findByIdAndUpdate(
        req.user._id,
        updates,
        { new: true }
      ).select('-password');

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      res.json({
        success: true,
        user
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating profile'
      });
    }
  }
);

// Follow user
router.post('/follow/:userId', protect, async (req, res) => {
  try {
    if (req.params.userId === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'You cannot follow yourself'
      });
    }

    const userToFollow = await User.findById(req.params.userId);
    if (!userToFollow) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const isAlreadyFollowing = req.user.following.includes(userToFollow._id);
    if (isAlreadyFollowing) {
      return res.status(400).json({
        success: false,
        message: 'You are already following this user'
      });
    }

    // Add to following
    await User.findByIdAndUpdate(req.user._id, {
      $push: { following: userToFollow._id }
    });

    // Add to followers
    await User.findByIdAndUpdate(userToFollow._id, {
      $push: { followers: req.user._id }
    });

    res.json({
      success: true,
      message: 'Successfully followed user'
    });
  } catch (error) {
    console.error('Follow user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error following user'
    });
  }
});

// Unfollow user
router.post('/unfollow/:userId', protect, async (req, res) => {
  try {
    if (req.params.userId === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'You cannot unfollow yourself'
      });
    }

    const userToUnfollow = await User.findById(req.params.userId);
    if (!userToUnfollow) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const isFollowing = req.user.following.includes(userToUnfollow._id);
    if (!isFollowing) {
      return res.status(400).json({
        success: false,
        message: 'You are not following this user'
      });
    }

    // Remove from following
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { following: userToUnfollow._id }
    });

    // Remove from followers
    await User.findByIdAndUpdate(userToUnfollow._id, {
      $pull: { followers: req.user._id }
    });

    res.json({
      success: true,
      message: 'Successfully unfollowed user'
    });
  } catch (error) {
    console.error('Unfollow user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error unfollowing user'
    });
  }
});

// Get user followers
router.get('/:userId/followers', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .populate('followers', '-password')
      .select('followers');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      followers: user.followers
    });
  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching followers'
    });
  }
});

// Get user following
router.get('/:userId/following', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .populate('following', '-password')
      .select('following');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      following: user.following
    });
  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching following'
    });
  }
});

module.exports = router; 