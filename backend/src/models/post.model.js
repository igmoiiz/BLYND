const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  userProfileImage: String,
  text: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const mediaSchema = new mongoose.Schema({
  url: { type: String, required: true },
  type: { type: String, enum: ['image', 'video'], required: true },
});

const postSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userEmail: {
    type: String,
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  userProfileImage: String,
  caption: String,
  media: [mediaSchema],
  likeCount: {
    type: Number,
    default: 0
  },
  likedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  comments: [commentSchema]
}, {
  timestamps: true
});

// Convert to frontend format
postSchema.methods.toClientFormat = function() {
  return {
    postId: this._id,
    userEmail: this.userEmail,
    userId: this.userId,
    userName: this.userName,
    userProfileImage: this.userProfileImage,
    caption: this.caption,
    media: this.media,
    likeCount: this.likeCount,
    likedBy: this.likedBy.map(id => id.toString()),
    comments: this.comments.map(comment => ({
      userId: comment.userId.toString(),
      userName: comment.userName,
      userProfileImage: comment.userProfileImage,
      text: comment.text,
      createdAt: comment.createdAt
    })),
    createdAt: this.createdAt
  };
};

// Add indexes for better query performance
postSchema.index({ userId: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 });

const Post = mongoose.model('Post', postSchema);

module.exports = Post; 