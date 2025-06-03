// Run with: node migrate_posts_media.js
const mongoose = require('mongoose');
const Post = require('./src/models/post.model');

const MONGO_URI = "MONGODB_URI"; // Change to your DB

async function migrate() {
  await mongoose.connect(MONGO_URI);

  const posts = await Post.find({ media: { $exists: false }, postImage: { $exists: true, $ne: null } });

  for (const post of posts) {
    if (post.postImage) {
      post.media = [{ url: post.postImage, type: 'image' }];
      post.markModified('media');
      await post.save();
      console.log(`Migrated post ${post._id}`);
    }
  }

  console.log('Migration complete!');
  mongoose.disconnect();
}

migrate().catch(err => {
  console.error(err);
  process.exit(1);
}); 