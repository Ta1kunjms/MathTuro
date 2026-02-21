// lessonplan-dnd.js
// Handles drag-and-drop, file card grid, preview, edit, delete for lesson plan files
// Requires: supabase.js, utils.js


const LESSON_PLAN_BUCKET = 'lesson-plans';
const LESSON_PLAN_TABLE = 'lesson_plan_files';

// --- State management for enhanced features ---
let selectedFiles = new Set();
let allFiles = [];
let currentSearch = '';
let currentSort = 'date_desc';
let currentTag = '';
let isLoading = false;

// Utility: Format bytes
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

// Utility: Get file icon by type
function getFileIcon(type) {
  if (!type) return 'fa-file';
  if (type.includes('pdf')) return 'fa-file-pdf text-red-600';
  if (type.includes('word') || type.includes('doc')) return 'fa-file-word text-blue-700';
  if (type.includes('powerpoint') || type.includes('ppt')) return 'fa-file-powerpoint text-orange-500';
  if (type.includes('excel') || type.includes('spreadsheet') || type.includes('xls')) return 'fa-file-excel text-green-600';
  if (type.includes('image')) return 'fa-file-image text-yellow-500';
  if (type.includes('zip') || type.includes('rar')) return 'fa-file-zipper text-purple-600';
  return 'fa-file text-gray-400';
}

// Utility: Create a progress bar for uploads
function createProgressBar(filename) {
  let bar = document.createElement('progress');
  bar.max = 100;
  bar.value = 0;
  bar.className = 'w-full my-2';
  let label = document.createElement('div');
  label.className = 'text-xs text-gray-600 mb-1';
  label.textContent = `Uploading: ${filename}`;
  let container = document.createElement('div');
  container.appendChild(label);
  container.appendChild(bar);
  document.getElementById('fileCardsGrid').prepend(container);
  return bar;
}

// Drag and drop logic
function setupDragAndDrop() {
  const uploadZone = document.getElementById('uploadZone');
  const fileInput = document.getElementById('fileInput');
  const browseFiles = document.getElementById('browseFiles');

  uploadZone.addEventListener('dragover', e => {
    e.preventDefault();
    uploadZone.classList.add('bg-green-200');
  });
  uploadZone.addEventListener('dragleave', e => {
    e.preventDefault();
    uploadZone.classList.remove('bg-green-200');
  });
  uploadZone.addEventListener('drop', e => {
    e.preventDefault();
    uploadZone.classList.remove('bg-green-200');
    handleFilesUpload(e.dataTransfer.files);
  });
  uploadZone.addEventListener('click', () => fileInput.click());
  browseFiles.addEventListener('click', e => {
    e.stopPropagation();
    fileInput.click();
  });
  fileInput.addEventListener('change', e => handleFilesUpload(e.target.files));
}

// Enhanced: Upload files with progress bar and support for multi-file
async function handleFilesUpload(files) {
  if (!files || files.length === 0) return;
  for (const file of files) {
    if (file.size > 20 * 1024 * 1024) {
      showToast(`File ${file.name} is too large (max 20MB)`, 'error');
      continue;
    }
    await uploadFileWithProgress(file);
  }
  await loadFiles();
}

// Enhanced: Upload file with progress bar
async function uploadFileWithProgress(file) {
  const user = await getCurrentUser();
  if (!user) {
    showToast('You must be logged in to upload.', 'error');
    return;
  }
  const supabase = getSupabase();
  const filePath = `${user.id}/${Date.now()}_${file.name}`;
  // Progress bar
  const progressBar = createProgressBar(file.name);
  // Use fetch to upload with progress (signed URL)
  const { data, error } = await supabase.storage.from(LESSON_PLAN_BUCKET).createSignedUploadUrl(filePath);
  if (error || !data) {
    showToast('Upload failed: ' + (error?.message || 'No upload URL'), 'error');
    progressBar.remove();
    return;
  }
  await new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('PUT', data.signedUrl, true);
    xhr.upload.onprogress = function (e) {
      if (e.lengthComputable) {
        const percent = Math.round((e.loaded / e.total) * 100);
        progressBar.value = percent;
      }
    };
    xhr.onload = async function () {
      progressBar.value = 100;
      setTimeout(() => progressBar.remove(), 500);
      if (xhr.status === 200) {
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
          description: '',
          tags: [],
        });
        if (dbError) showToast('Failed to save file info: ' + dbError.message, 'error');
        else showToast('File uploaded successfully!', 'success');
        resolve();
      } else {
        showToast('Upload failed: ' + xhr.statusText, 'error');
        reject();
      }
    };
    xhr.onerror = function () {
      showToast('Upload failed: Network error', 'error');
      progressBar.remove();
      reject();
    };
    xhr.send(file);
  });
}

// Handle file upload
async function handleFilesUpload(files) {
  if (!files || files.length === 0) return;
  for (const file of files) {
    if (file.size > 20 * 1024 * 1024) {
      showToast(`File ${file.name} is too large (max 20MB)`, 'error');
      continue;
    }
    await uploadFile(file);
  }
  await loadFiles();
}

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

async function uploadFile(file) {
  const user = await getCurrentUser();
  if (!user) {
    showToast('You must be logged in to upload.', 'error');
    return;
  }
  const supabase = getSupabase();
  const filePath = `${user.id}/${Date.now()}_${file.name}`;
  // Upload to storage
  const { error } = await supabase.storage.from(LESSON_PLAN_BUCKET).upload(filePath, file);
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
    description: '',
  });
  if (dbError) {
    showToast('Failed to save file info: ' + dbError.message, 'error');
    return;
  }
  showToast('File uploaded successfully!', 'success');
}

// Load and display files as cards
async function loadFiles() {
  const user = await getCurrentUser();
  if (!user) return;
  const supabase = getSupabase();
  let query = supabase.from(LESSON_PLAN_TABLE).select('*').eq('user_id', user.id);
  if (currentTag) query = query.contains('tags', [currentTag]);
  let { data: files, error } = await query;
  if (error) files = [];
  // Search
  if (currentSearch) files = files.filter(f => f.file_name.toLowerCase().includes(currentSearch.toLowerCase()));
  // Sort
  files = files || [];
  if (currentSort === 'date_desc') files.sort((a, b) => new Date(b.uploaded_at) - new Date(a.uploaded_at));
  if (currentSort === 'date_asc') files.sort((a, b) => new Date(a.uploaded_at) - new Date(b.uploaded_at));
  if (currentSort === 'name_asc') files.sort((a, b) => a.file_name.localeCompare(b.file_name));
  if (currentSort === 'name_desc') files.sort((a, b) => b.file_name.localeCompare(a.file_name));
  allFiles = files;
  renderFileCards();
  isLoading = false;
}

function renderFileCards() {
  const grid = document.getElementById('fileCardsGrid');
  const emptyState = document.getElementById('emptyState');
  grid.innerHTML = '';
  if (!allFiles.length) {
    emptyState.classList.remove('hidden');
    return;
  }
  emptyState.classList.add('hidden');
  allFiles.forEach(file => {
    const card = document.createElement('div');
    card.className = 'bg-white border border-gray-200 rounded-2xl shadow-sm hover:shadow-md transition-shadow p-5 flex flex-col gap-3';

    const periodBadge = file.period_type && file.period_value
      ? `<span class="inline-flex items-center gap-1 bg-green-50 text-green-700 border border-green-200 text-xs font-medium px-2 py-0.5 rounded-full capitalize">
           <i class="fa-solid fa-calendar-days text-[10px]"></i>${escapeHtml(file.period_type)} ${escapeHtml(file.period_value)}
         </span>`
      : '';

    const moduleBadge = file.module_name
      ? `<span class="inline-flex items-center gap-1 bg-blue-50 text-blue-700 border border-blue-200 text-xs font-medium px-2 py-0.5 rounded-full truncate max-w-full">
           <i class="fa-solid fa-book-open text-[10px]"></i>${escapeHtml(file.module_name)}${file.lesson_name ? ' › ' + escapeHtml(file.lesson_name) : ''}
         </span>`
      : '';

    const tagBadges = (file.tags || []).map(tag =>
      `<span class="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">${escapeHtml(tag)}</span>`
    ).join('');

    card.innerHTML = `
      <div class="flex items-start gap-3">
        <input type="checkbox" class="file-select mt-1 accent-green-700" data-id="${file.id}" ${selectedFiles.has(file.id) ? 'checked' : ''}>
        <div class="w-10 h-10 flex-shrink-0 flex items-center justify-center rounded-xl bg-gray-100">
          <i class="fa-solid ${getFileIcon(file.file_type)} text-2xl"></i>
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-semibold text-gray-800 text-sm leading-snug truncate" title="${escapeHtml(file.file_name)}">${escapeHtml(file.file_name)}</div>
          <div class="text-xs text-gray-400 mt-0.5">${formatBytes(file.file_size)} &bull; ${formatDate(file.uploaded_at)}</div>
        </div>
      </div>

      ${(moduleBadge || periodBadge) ? `
      <div class="flex flex-wrap gap-1.5">
        ${moduleBadge}
        ${periodBadge}
      </div>` : ''}

      ${file.description ? `<p class="text-xs text-gray-500 leading-relaxed line-clamp-2">${escapeHtml(file.description)}</p>` : ''}

      ${tagBadges ? `<div class="flex flex-wrap gap-1">${tagBadges}</div>` : ''}

      <div class="flex gap-2 pt-1 border-t border-gray-100 mt-auto">
        <button class="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 bg-green-700 text-white rounded-xl hover:bg-green-800 text-xs font-semibold transition-colors" onclick="previewFile('${file.file_path}')">
          <i class="fa-solid fa-eye"></i> Preview
        </button>
        <button class="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-xs font-semibold transition-colors" onclick="editFilePrompt('${file.id}')">
          <i class="fa-solid fa-pen"></i> Edit
        </button>
        <button class="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 bg-red-500 text-white rounded-xl hover:bg-red-600 text-xs font-semibold transition-colors" onclick="deleteFile('${file.id}', '${file.file_path}')">
          <i class="fa-solid fa-trash"></i> Delete
        </button>
      </div>
    `;
    grid.appendChild(card);
  });
  // Multi-select logic
  grid.querySelectorAll('.file-select').forEach(cb => {
    cb.addEventListener('change', e => {
      const id = cb.getAttribute('data-id');
      if (cb.checked) selectedFiles.add(id); else selectedFiles.delete(id);
      updateMultiSelectBar();
    });
  });
  updateMultiSelectBar();
}

function updateMultiSelectBar() {
  let bar = document.getElementById('multiSelectBar');
  if (!bar) {
    bar = document.createElement('div');
    bar.id = 'multiSelectBar';
    bar.className = 'fixed bottom-4 left-1/2 -translate-x-1/2 bg-white border border-gray-200 shadow-lg rounded-xl px-6 py-3 flex gap-4 items-center z-50';
    document.body.appendChild(bar);
  }
  if (!selectedFiles.size) { bar.style.display = 'none'; return; }
  bar.style.display = 'flex';
  bar.innerHTML = `<span class='font-semibold'>${selectedFiles.size} selected</span>
    <button class='bg-red-600 text-white px-4 py-1 rounded hover:bg-red-700' onclick='deleteSelectedFiles()'><i class='fa-solid fa-trash mr-1'></i>Delete Selected</button>`;
}

async function deleteSelectedFiles() {
  if (!(await showConfirmModal('Delete Files', `Delete ${selectedFiles.size} selected files?`, 'Delete', 'Cancel', 'danger'))) return;
  const supabase = getSupabase();
  for (const id of selectedFiles) {
    const file = allFiles.find(f => f.id == id);
    if (file) {
      await supabase.storage.from(LESSON_PLAN_BUCKET).remove([file.file_path]);
      await supabase.from(LESSON_PLAN_TABLE).delete().eq('id', id);
    }
  }
  showToast('Files deleted.', 'success');
  selectedFiles.clear();
  await loadFiles();
}


// Preview file using a signed URL (works for private buckets)
async function previewFile(filePath) {
  const supabase = getSupabase();
  // Generate a signed URL valid for 60 minutes
  const { data, error } = await supabase.storage
    .from(LESSON_PLAN_BUCKET)
    .createSignedUrl(filePath, 3600);

  if (error || !data) {
    showToast('Could not generate preview link: ' + (error?.message || 'Unknown error'), 'error');
    return;
  }

  const signedUrl = data.signedUrl;
  if (filePath.match(/\.(pdf|jpg|jpeg|png|gif)$/i)) {
    showPreviewModal(signedUrl, filePath);
  } else {
    window.open(signedUrl, '_blank');
  }
}

function showPreviewModal(url, filePath) {
  // Remove existing modal if present
  const existing = document.getElementById('previewModal');
  if (existing) existing.remove();

  const modal = document.createElement('div');
  modal.id = 'previewModal';
  modal.className = 'fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50';
  modal.innerHTML = `
    <div class='bg-white rounded-xl shadow-lg max-w-4xl w-full mx-4 p-4 relative' style='max-height:90vh;'>
      <button class='absolute top-2 right-2 text-gray-600 hover:text-black text-2xl z-10' onclick='document.getElementById("previewModal").remove()'>&times;</button>
      <div id='previewContent' class='w-full flex items-center justify-center' style='height:80vh;'></div>
    </div>`;
  document.body.appendChild(modal);

  const content = modal.querySelector('#previewContent');
  if (filePath && filePath.match(/\.pdf$/i)) {
    content.innerHTML = `<iframe src='${url}' class='w-full h-full rounded' frameborder='0'></iframe>`;
  } else {
    content.innerHTML = `<img src='${url}' class='max-h-full max-w-full rounded object-contain' />`;
  }
}

// Edit file (rename, description, tags) in modal
async function editFilePrompt(fileId) {
  const file = allFiles.find(f => f.id == fileId);
  if (!file) return;
  // Modal for edit
  let modal = document.getElementById('editModal');
  if (!modal) {
    modal = document.createElement('div');
    modal.id = 'editModal';
    modal.className = 'fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50';
    modal.innerHTML = `<div class='bg-white rounded-xl shadow-lg max-w-md w-full p-6 relative'>
      <button class='absolute top-2 right-2 text-gray-600 hover:text-black text-2xl' onclick='document.getElementById("editModal").remove()'>&times;</button>
      <h2 class='text-lg font-bold mb-4'>Edit File</h2>
      <form id='editFileForm' class='flex flex-col gap-3'>
        <label class='text-sm font-semibold'>File Name
          <input type='text' id='editFileName' class='w-full border border-gray-300 rounded px-3 py-2 mt-1' value='${escapeHtml(file.file_name)}' required />
        </label>
        <label class='text-sm font-semibold'>Description
          <textarea id='editFileDesc' class='w-full border border-gray-300 rounded px-3 py-2 mt-1'>${escapeHtml(file.description||'')}</textarea>
        </label>
        <label class='text-sm font-semibold'>Tags (comma separated)
          <input type='text' id='editFileTags' class='w-full border border-gray-300 rounded px-3 py-2 mt-1' value='${(file.tags||[]).join(", ")}' />
        </label>
        <button type='submit' class='bg-green-700 text-white px-4 py-2 rounded hover:bg-green-800 mt-2'>Save</button>
      </form>
    </div>`;
    document.body.appendChild(modal);
  }
  const form = modal.querySelector('#editFileForm');
  form.onsubmit = async (e) => {
    e.preventDefault();
    const newName = form.querySelector('#editFileName').value.trim();
    const newDesc = form.querySelector('#editFileDesc').value.trim();
    const newTags = form.querySelector('#editFileTags').value.split(',').map(t => t.trim()).filter(Boolean);
    const supabase = getSupabase();
    await supabase.from(LESSON_PLAN_TABLE).update({ file_name: newName, description: newDesc, tags: newTags }).eq('id', fileId);
    showToast('File updated.', 'success');
    modal.remove();
    await loadFiles();
  };
}

// Delete file
async function deleteFile(fileId, filePath) {
  if (!(await showConfirmModal('Delete File', 'Are you sure you want to delete this file?', 'Delete', 'Cancel', 'danger'))) return;
  const supabase = getSupabase();
  await supabase.storage.from(LESSON_PLAN_BUCKET).remove([filePath]);
  await supabase.from(LESSON_PLAN_TABLE).delete().eq('id', fileId);
  showToast('File deleted.', 'success');
  await loadFiles();
}

// Search and sort
function setupSearchAndSort() {
  const searchInput = document.getElementById('searchInput');
  const sortSelect = document.getElementById('sortSelect');
  searchInput.addEventListener('input', e => {
    currentSearch = searchInput.value;
    loadFiles();
  });
  sortSelect.addEventListener('change', e => {
    currentSort = sortSelect.value;
    loadFiles();
  });
}

// Toast notification (uses utils.js)
// showToast(message, type)

// On page load
// --- Module, Lesson, Period Selectors Logic ---
let modulesList = [];
let lessonsByModule = {};
let currentModule = '';
let currentLesson = '';
let currentPeriodType = '';
let currentPeriodValue = '';

function setupSelectors() {
  const moduleSelect = document.getElementById('moduleSelect');
  const lessonSelect = document.getElementById('lessonSelect');
  const periodTypeSelect = document.getElementById('periodTypeSelect');
  const periodValueInput = document.getElementById('periodValueInput');

  moduleSelect.addEventListener('input', e => {
    currentModule = moduleSelect.value.trim();
  });
  lessonSelect.addEventListener('input', e => {
    currentLesson = lessonSelect.value.trim();
  });
  periodTypeSelect.addEventListener('change', e => {
    currentPeriodType = periodTypeSelect.value;
  });
  periodValueInput.addEventListener('input', e => {
    currentPeriodValue = periodValueInput.value;
  });
}

// Override handleFilesUpload to require selectors
async function handleFilesUpload(files) {
  if (!files || files.length === 0) return;
  // Validate inputs
  const moduleSelect = document.getElementById('moduleSelect');
  const lessonSelect = document.getElementById('lessonSelect');
  const periodTypeSelect = document.getElementById('periodTypeSelect');
  const periodValueInput = document.getElementById('periodValueInput');
  if (!moduleSelect.value.trim()) {
    showToast('Please enter a module name.', 'error');
    return;
  }
  if (!periodTypeSelect.value) {
    showToast('Please select a period type.', 'error');
    return;
  }
  if (!periodValueInput.value.trim()) {
    showToast('Please enter a period value.', 'error');
    return;
  }
  for (const file of files) {
    if (file.size > 20 * 1024 * 1024) {
      showToast(`File ${file.name} is too large (max 20MB)`, 'error');
      continue;
    }
    await uploadFileWithProgress(file, moduleSelect.value.trim(), lessonSelect.value.trim(), periodTypeSelect.value, periodValueInput.value.trim());
  }
  await loadFiles();
}

// Upload file with progress indicator using direct Supabase storage upload
async function uploadFileWithProgress(file, moduleName, lessonName, periodType, periodValue) {
  const user = await getCurrentUser();
  if (!user) {
    showToast('You must be logged in to upload.', 'error');
    return;
  }
  const supabase = getSupabase();
  const filePath = `${user.id}/${Date.now()}_${file.name}`;
  const progressBar = createProgressBar(file.name);

  // Direct upload to Supabase Storage
  const { error: uploadError } = await supabase.storage
    .from(LESSON_PLAN_BUCKET)
    .upload(filePath, file, { upsert: false });

  progressBar.value = 100;
  setTimeout(() => progressBar.remove(), 500);

  if (uploadError) {
    showToast('Upload failed: ' + uploadError.message, 'error');
    return;
  }

  // Get public URL
  const { data: publicUrlData } = supabase.storage
    .from(LESSON_PLAN_BUCKET)
    .getPublicUrl(filePath);

  // Save metadata to DB
  const { error: dbError } = await supabase.from(LESSON_PLAN_TABLE).insert({
    user_id: user.id,
    file_name: file.name,
    file_path: filePath,
    file_url: publicUrlData.publicUrl,
    file_type: file.type,
    file_size: file.size,
    uploaded_at: new Date().toISOString(),
    description: '',
    tags: [],
    module_name: moduleName,
    lesson_name: lessonName || null,
    period_type: periodType,
    period_value: periodValue
  });

  if (dbError) showToast('Failed to save file info: ' + dbError.message, 'error');
  else showToast('File uploaded successfully!', 'success');
}

// Filtering/grouping logic for file loading
let currentModuleFilter = '';
let currentLessonFilter = '';
let currentPeriodTypeFilter = '';
let currentPeriodValueFilter = '';

function setupFilterSelectors() {
  const periodTypeSelect = document.getElementById('periodTypeSelect');
  const periodValueInput = document.getElementById('periodValueInput');
  periodTypeSelect.addEventListener('change', () => { currentPeriodTypeFilter = periodTypeSelect.value; loadFiles(); });
  periodValueInput.addEventListener('input', () => { currentPeriodValueFilter = periodValueInput.value; loadFiles(); });
}

// Update loadFiles to filter by selectors
async function loadFiles() {
  const user = await getCurrentUser();
  if (!user) return;
  const supabase = getSupabase();
  let query = supabase.from(LESSON_PLAN_TABLE).select('*').eq('user_id', user.id);
  if (currentTag) query = query.contains('tags', [currentTag]);
  if (currentPeriodTypeFilter) query = query.eq('period_type', currentPeriodTypeFilter);
  if (currentPeriodValueFilter) query = query.eq('period_value', currentPeriodValueFilter);
  let { data: files, error } = await query;
  if (error) files = [];
  // Search
  if (currentSearch) files = files.filter(f => f.file_name.toLowerCase().includes(currentSearch.toLowerCase()));
  // Sort
  files = files || [];
  if (currentSort === 'date_desc') files.sort((a, b) => new Date(b.uploaded_at) - new Date(a.uploaded_at));
  if (currentSort === 'date_asc') files.sort((a, b) => new Date(a.uploaded_at) - new Date(b.uploaded_at));
  if (currentSort === 'name_asc') files.sort((a, b) => a.file_name.localeCompare(b.file_name));
  if (currentSort === 'name_desc') files.sort((a, b) => b.file_name.localeCompare(a.file_name));
  allFiles = files;
  renderFileCards();
  isLoading = false;
}

window.addEventListener('DOMContentLoaded', async () => {
  setupSelectors();
  setupDragAndDrop();
  setupSearchAndSort();
  setupFilterSelectors();
  loadFiles();
});
