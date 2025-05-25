const { createClient } = require('@supabase/supabase-js');

let supabase = null;

// Initialize Supabase client if credentials are available
if (process.env.SUPABASE_URL && process.env.SUPABASE_KEY) {
  supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
  );
}

const ensureBucketExists = async (bucketName) => {
  if (!supabase) {
    console.log('Supabase not configured, skipping bucket creation');
    return;
  }

  try {
    const { data: bucket } = await supabase.storage.getBucket(bucketName);
    
    if (!bucket) {
      await supabase.storage.createBucket(bucketName, {
        public: true,
        allowedMimeTypes: ['image/png', 'image/jpeg', 'image/gif']
      });
    }
  } catch (error) {
    console.error('Error ensuring bucket exists:', error);
    // Don't throw error, just log it
  }
};

const uploadUserImage = async (file, userName) => {
  if (!supabase) {
    console.log('Supabase not configured, skipping image upload');
    return '';
  }

  try {
    const timestamp = Date.now();
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${userName}-${timestamp}.${fileExt}`;

    const { data, error } = await supabase.storage
      .from(process.env.SUPABASE_USER_BUCKET)
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true
      });

    if (error) throw error;

    const { data: publicUrl } = supabase.storage
      .from(process.env.SUPABASE_USER_BUCKET)
      .getPublicUrl(fileName);

    return publicUrl.publicUrl;
  } catch (error) {
    console.error('Error uploading user image:', error);
    return '';
  }
};

class SupabaseService {
  constructor() {
    this.userBucket = process.env.SUPABASE_USER_BUCKET;
    this.postBucket = process.env.SUPABASE_POST_BUCKET;
  }

  async uploadPostImage(file, userId) {
    try {
      const timestamp = Date.now();
      const fileName = `post_${userId}_${timestamp}.jpg`;

      const { data, error } = await supabase.storage
        .from(this.postBucket)
        .upload(fileName, file.buffer, {
          contentType: 'image/jpeg',
          cacheControl: '3600',
          upsert: true
        });

      if (error) throw error;

      const { data: { publicUrl } } = supabase.storage
        .from(this.postBucket)
        .getPublicUrl(fileName);

      return publicUrl;
    } catch (error) {
      console.error('Error uploading post image:', error);
      throw error;
    }
  }

  async deleteImage(bucket, fileName) {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .remove([fileName]);

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error deleting image:', error);
      throw error;
    }
  }
}

module.exports = {
  ensureBucketExists,
  uploadUserImage,
  SupabaseService
}; 