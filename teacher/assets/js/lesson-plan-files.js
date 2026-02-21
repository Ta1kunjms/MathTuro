// lesson-plan-files.js
// Handles lesson plan file upload, listing, and deletion for teachers
// Requires: supabase.js, utils.js

const LESSON_PLAN_BUCKET = 'lesson-plans'; // Make sure this bucket exists in Supabase Storage
const LESSON_PLAN_TABLE = 'lesson_plan_files'; // Make sure this table exists in Supabase DB

// Utility: Format bytes to human readable
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Utility: Format date
function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleString();
}

// Get current teacher user (returns user object or null)
async function getCurrentUser() {
  const supabase = getSupabase();
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', session.user.id)
    .single();
  return user;
}

// Upload file handler
async function handleLessonPlanFileUpload(e) {
  e.preventDefault();
  const fileInput = document.getElementById('lessonPlanFileInput');
  const file = fileInput.files[0];
  if (!file) return;
  const user = await getCurrentUser();
  if (!user) {
    showToast('You must be logged in to upload.', 'error');
    return;
  }
  const supabase = getSupabase();
  const filePath = `${user.id}/${Date.now()}_${file.name}`;
  // Upload to storage
  const { data, error } = await supabase.storage.from(LESSON_PLAN_BUCKET).upload(filePath, file);
  if (error) {
    showToast('Upload failed: ' + error.message, 'error');
    return;
  }
  // Get public URL
  const { data: publicUrlData } = supabase.storage.from(LESSON_PLAN_BUCKET).getPublicUrl(filePath);
  // Save metadata to DB
  const { error: dbError } = await supabase.from(LESSON_PLAN_TABLE).insert({
    user_id: user.id,
    file_name: file.name,
    file_path: filePath,
    file_url: publicUrlData.publicUrl,
    file_type: file.type,
    file_size: file.size,
    uploaded_at: new Date().toISOString(),
  });
  if (dbError) {
    showToast('Failed to save file info: ' + dbError.message, 'error');
    return;
  }
  showToast('File uploaded successfully!', 'success');
  fileInput.value = '';
  await loadLessonPlanFiles();
}

// Load and display files
async function loadLessonPlanFiles() {
  const user = await getCurrentUser();
  if (!user) return;
  const supabase = getSupabase();
  const { data: files, error } = await supabase
    .from(LESSON_PLAN_TABLE)
    .select('*')
    .eq('user_id', user.id)
    .order('uploaded_at', { ascending: false });
  const list = document.getElementById('lessonPlanFilesList');
  const noFilesMsg = document.getElementById('noFilesMsg');
  list.innerHTML = '';
  // Update summary cards
  const total = files ? files.length : 0;
  const pdf = files ? files.filter(f => (f.file_type||'').toLowerCase().includes('pdf')).length : 0;
  const doc = files ? files.filter(f => /(word|doc|docx|application\/msword|application\/vnd\.openxmlformats-officedocument\.wordprocessingml\.document)/i.test(f.file_type)).length : 0;
  const other = total - pdf - doc;
  if (document.getElementById('lessonPlanTotalFiles')) document.getElementById('lessonPlanTotalFiles').textContent = total;
  if (document.getElementById('lessonPlanPdfFiles')) document.getElementById('lessonPlanPdfFiles').textContent = pdf;
  if (document.getElementById('lessonPlanDocFiles')) document.getElementById('lessonPlanDocFiles').textContent = doc;
  if (document.getElementById('lessonPlanOtherFiles')) document.getElementById('lessonPlanOtherFiles').textContent = other;
  if (error || !files || files.length === 0) {
    noFilesMsg.classList.remove('hidden');
    return;
  }
  noFilesMsg.classList.add('hidden');
  files.forEach(file => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class=\"px-4 py-2\">${escapeHtml(file.file_name)}</td>
      <td class=\"px-4 py-2\">${escapeHtml(file.file_type || 'Unknown')}</td>
      <td class=\"px-4 py-2\">${formatBytes(file.file_size)}</td>
      <td class=\"px-4 py-2\">${formatDate(file.uploaded_at)}</td>
      <td class=\"px-4 py-2 flex gap-2\">
        <a href=\"${file.file_url}\" target=\"_blank\" class=\"text-blue-600 hover:underline\">View</a>
        <button class=\"text-red-600 hover:underline\" onclick=\"deleteLessonPlanFile('${file.id}', '${file.file_path}')\">Delete</button>
      </td>
    `;
    list.appendChild(tr);
  });
}

// Delete file handler
async function deleteLessonPlanFile(fileId, filePath) {
  if (!(await showConfirmModal('Delete File', 'Are you sure you want to delete this file?', 'Delete', 'Cancel', 'danger'))) return;
  const supabase = getSupabase();
  // Remove from storage
  const { error: storageError } = await supabase.storage.from(LESSON_PLAN_BUCKET).remove([filePath]);
  if (storageError) {
    showToast('Failed to delete file from storage: ' + storageError.message, 'error');
    return;
  }
  // Remove from DB
  const { error: dbError } = await supabase.from(LESSON_PLAN_TABLE).delete().eq('id', fileId);
  if (dbError) {
    showToast('Failed to delete file record: ' + dbError.message, 'error');
    return;
  }
  showToast('File deleted.', 'success');
  await loadLessonPlanFiles();
}

// Setup event listeners
window.addEventListener('DOMContentLoaded', () => {
  const uploadForm = document.getElementById('lessonPlanFileUploadForm');
  if (uploadForm) uploadForm.onsubmit = handleLessonPlanFileUpload;
  loadLessonPlanFiles();
});
