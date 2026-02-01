/*
  File: uploads.js
  Purpose:
  - Handles all file upload functionality
  - Manages quiz screenshot uploads
  - Handles learning material file uploads (PDF, images, etc.)
  - Generates public URLs for uploaded files

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
*/

/*
  Function Name: uploadQuizScreenshot
  Purpose:
  - Uploads a quiz screenshot to Supabase Storage
  - Generates a public URL for the uploaded file
  - Stores the file in a structured storage path

  When it runs:
  - Called when student submits a quiz score with a screenshot
  - Called when student resubmits a quiz with a new screenshot

  Who can use it:
  - Student

  Backend interaction:
  - Uploads file to Supabase Storage bucket
  - Sets file permissions to public
  - Generates and returns public URL

  Error handling:
  - Validates file type and size
  - Handles upload errors
  - Handles public URL generation errors
  - Shows alert for errors
*/
async function uploadQuizScreenshot(lessonId, studentId, file) {
  try {
    // Validate file
    if (!file) {
      return { success: false, error: 'No file selected' };
    }

    // Check file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(file.type)) {
      return { success: false, error: 'Only image files (JPEG, PNG, WebP, GIF) are allowed' };
    }

    // Check file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return { success: false, error: 'File size must be less than 5MB' };
    }

    // Generate unique filename
    const timestamp = Date.now();
    const extension = file.type.split('/')[1];
    const filename = `${studentId}_lesson${lessonId}_${timestamp}.${extension}`;
    const storagePath = `quiz_screenshots/${filename}`;

    // Upload file to Supabase Storage
    const { error: uploadError } = await getSupabase().storage
      .from('quiz-screenshots')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) {
      throw new Error(uploadError.message);
    }

    // Get public URL
    const { data: publicUrlData } = getSupabase().storage
      .from('quiz-screenshots')
      .getPublicUrl(storagePath);

    if (!publicUrlData) {
      throw new Error('Failed to get public URL');
    }

    return {
      success: true,
      url: publicUrlData.publicUrl,
      filename: filename
    };

  } catch (error) {
    console.error('Error uploading quiz screenshot:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/*
  Function Name: uploadLearningMaterial
  Purpose:
  - Uploads learning material files (PDF, images, documents) to Supabase Storage
  - Generates a public URL for the uploaded file
  - Stores the file in a structured storage path

  When it runs:
  - Called when teacher uploads learning materials
  - Called when admin uploads learning materials

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Uploads file to Supabase Storage bucket
  - Sets file permissions to public
  - Generates and returns public URL

  Error handling:
  - Validates file type and size
  - Handles upload errors
  - Handles public URL generation errors
  - Shows alert for errors
*/
async function uploadLearningMaterial(moduleId, lessonId, file) {
  try {
    // Validate file
    if (!file) {
      return { success: false, error: 'No file selected' };
    }

    // Check file type
    const allowedTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain'
    ];

    if (!allowedTypes.includes(file.type)) {
      return { success: false, error: 'File type not supported' };
    }

    // Check file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return { success: false, error: 'File size must be less than 10MB' };
    }

    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return { success: false, error: 'You do not have permission to upload files' };
    }

    // Generate unique filename
    const timestamp = Date.now();
    const extension = file.name.split('.').pop();
    const filename = `${moduleId}_${lessonId}_${timestamp}.${extension}`;
    const storagePath = `learning_materials/${filename}`;

    // Upload file to Supabase Storage
    const { error: uploadError } = await getSupabase().storage
      .from('learning-materials')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (uploadError) {
      throw new Error(uploadError.message);
    }

    // Get public URL
    const { data: publicUrlData } = getSupabase().storage
      .from('learning-materials')
      .getPublicUrl(storagePath);

    if (!publicUrlData) {
      throw new Error('Failed to get public URL');
    }

    return {
      success: true,
      url: publicUrlData.publicUrl,
      filename: filename,
      size: file.size,
      type: file.type
    };

  } catch (error) {
    console.error('Error uploading learning material:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/*
  Function Name: deleteFile
  Purpose:
  - Deletes a file from Supabase Storage
  - Requires teacher or admin role

  When it runs:
  - Called when teacher deletes uploaded learning materials
  - Called when admin deletes uploaded files

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Deletes file from Supabase Storage bucket

  Error handling:
  - Validates user role
  - Handles deletion errors
  - Shows alert for errors
*/
async function deleteFile(bucketName, filePath) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to delete files', 'error');
      return false;
    }

    const { error } = await getSupabase().storage
      .from(bucketName)
      .remove([filePath]);

    if (error) {
      console.error('Error deleting file:', error);
      if (typeof showToast === 'function') showToast('Failed to delete file: ' + error.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error deleting file:', error);
    if (typeof showToast === 'function') showToast('Failed to delete file. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: validateFile
  Purpose:
  - Validates file type and size before upload
  - Checks if file meets requirements

  When it runs:
  - Called before upload functions
  - Can be called directly for validation

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - N/A - client-side validation only

  Error handling:
  - Returns validation error message if file is invalid
  - Returns null if file is valid
*/
function validateFile(file, allowedTypes, maxSize) {
  if (!file) {
    return 'No file selected';
  }

  if (!allowedTypes.includes(file.type)) {
    return 'File type not supported';
  }

  if (file.size > maxSize) {
    const maxSizeMB = (maxSize / (1024 * 1024)).toFixed(1);
    return `File size must be less than ${maxSizeMB}MB`;
  }

  return null;
}

/*
  Function Name: getFileSizeString
  Purpose:
  - Formats file size into human-readable string

  When it runs:
  - Called when displaying file information

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - N/A - client-side formatting only
*/
function getFileSizeString(bytes) {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
