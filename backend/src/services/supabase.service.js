const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = "https://xwckseuzeucwapvqrqqs.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3Y2tzZXV6ZXVjd2FwdnFycXFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyNTg0NDgsImV4cCI6MjA2MjgzNDQ0OH0.F-iEs5dpWLK8gsJfSJ4RRB29HYlggCmkK1-2bzrDJgw";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const BUCKET_NAMES = {
  USER_IMAGES: 'user-images',
  POST_IMAGES: 'post-images'
};

const ensureBucketExists = async (bucketName) => {
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
  try {
    const timestamp = Date.now();
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${userName}-${timestamp}.${fileExt}`;

    const { data, error } = await supabase.storage
      .from(BUCKET_NAMES.USER_IMAGES)
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true
      });

    if (error) throw error;

    const { data: publicUrl } = supabase.storage
      .from(BUCKET_NAMES.USER_IMAGES)
      .getPublicUrl(fileName);

    return publicUrl.publicUrl;
  } catch (error) {
    console.error('Error uploading user image:', error);
    return '';
  }
};

const uploadPostMedia = async (file, userId) => {
  try {
    const timestamp = Date.now();
    const fileExt = file.originalname.split('.').pop();
    const fileName = `post-${userId}-${timestamp}.${fileExt}`;

    // Ensure bucket allows video and image mime types
    await ensureBucketExists(BUCKET_NAMES.POST_IMAGES);

    const { data, error } = await supabase.storage
      .from(BUCKET_NAMES.POST_IMAGES)
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true
      });

    if (error) throw error;

    const { data: publicUrl } = supabase.storage
      .from(BUCKET_NAMES.POST_IMAGES)
      .getPublicUrl(fileName);

    return publicUrl.publicUrl;
  } catch (error) {
    console.error('Error uploading post media:', error);
    return '';
  }
};

const deleteImage = async (bucketName, fileName) => {
  try {
    const { data, error } = await supabase.storage
      .from(bucketName)
      .remove([fileName]);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error deleting image:', error);
    return false;
  }
};

module.exports = {
  BUCKET_NAMES,
  ensureBucketExists,
  uploadUserImage,
  uploadPostMedia,
  deleteImage
}; 