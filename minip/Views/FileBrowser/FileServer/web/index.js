// Current path
let currentPath = "";
let currentFile = null;
let currentAction = null;
let filesToUpload = [];
let isUploading = false;

// DOM elements
const fileListContent = document.getElementById("file-list-content");
const breadcrumb = document.getElementById("breadcrumb");
const confirmModal = document.getElementById("confirmModal");
const confirmModalTitle = document.getElementById("confirmModalTitle");
const confirmModalMessage = document.getElementById("confirmModalMessage");
const confirmModalCancel = document.getElementById("confirmModalCancel");
const confirmModalConfirm = document.getElementById("confirmModalConfirm");
const renameModal = document.getElementById("renameModal");
const renameInput = document.getElementById("renameInput");
const renameModalCancel = document.getElementById("renameModalCancel");
const renameModalConfirm = document.getElementById("renameModalConfirm");
const createFileModal = document.getElementById("createFileModal");
const createFileInput = document.getElementById("createFileInput");
const createFileError = document.getElementById("createFileError");
const createFileModalCancel = document.getElementById("createFileModalCancel");
const createFileModalConfirm = document.getElementById("createFileModalConfirm");
const createFolderModal = document.getElementById("createFolderModal");
const createFolderInput = document.getElementById("createFolderInput");
const createFolderError = document.getElementById("createFolderError");
const createFolderModalCancel = document.getElementById("createFolderModalCancel");
const createFolderModalConfirm = document.getElementById("createFolderModalConfirm");
const toast = document.getElementById("toast");
const uploadModal = document.getElementById("uploadModal");
const fileInput = document.getElementById("fileInput");
const selectFileBtn = document.getElementById("selectFileBtn");
const uploadFileList = document.getElementById("uploadFileList");
const progressBar = document.getElementById("progressBar");
const uploadStatus = document.getElementById("uploadStatus");
const uploadModalCancel = document.getElementById("uploadModalCancel");
const uploadModalConfirm = document.getElementById("uploadModalConfirm");

// Initialization
document.addEventListener("DOMContentLoaded", () => {
  loadFiles(currentPath);

  // Confirm dialog events
  confirmModalCancel.addEventListener("click", () => {
    confirmModal.classList.remove("active");
  });

  confirmModalConfirm.addEventListener("click", () => {
    confirmModal.classList.remove("active");
    if (currentAction === "delete") {
      deleteFile();
    }
  });

  // Rename dialog events
  renameModalCancel.addEventListener("click", () => {
    renameModal.classList.remove("active");
  });

  renameModalConfirm.addEventListener("click", () => {
    renameModal.classList.remove("active");
    renameFile();
  });

  // Upload dialog events
  uploadModalCancel.addEventListener("click", () => {
    uploadModal.classList.remove("active");
    resetUploadForm();
  });

  uploadModalConfirm.addEventListener("click", () => {
    if (filesToUpload.length > 0 && !isUploading) {
      startUpload();
    }
  });

  // Create file dialog events
  createFileModalCancel.addEventListener("click", () => {
    createFileModal.classList.remove("active");
    clearError(createFileError);
  });

  createFileModalConfirm.addEventListener("click", () => {
    if (validateName(createFileInput.value, createFileError)) {
      createFileModal.classList.remove("active");
      createFile();
    }
  });

  // Create folder dialog events
  createFolderModalCancel.addEventListener("click", () => {
    createFolderModal.classList.remove("active");
    clearError(createFolderError);
  });

  createFolderModalConfirm.addEventListener("click", () => {
    if (validateName(createFolderInput.value, createFolderError)) {
      createFolderModal.classList.remove("active");
      createFolder();
    }
  });

  // File selection button event
  selectFileBtn.addEventListener("click", () => {
    fileInput.click();
  });

  // File input change event
  fileInput.addEventListener("change", handleFileSelection);
});

// Load file list
function loadFiles(path) {
  showLoading();

  fetch("/files", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      path,
    }),
  }).then(res => res.json())
    .then(res => {
      renderFileList(res);
      updateBreadcrumb(path);
    })
}

// Render file list
function renderFileList(files) {
  const footerEl = `
                    <div class="file-item" style="justify-content: center; grid-template-columns: 1fr;">
                      <div class="file-actions" style="justify-content: center;">
                        <button class="action-btn create-btn" data-action="create-file">
                          <i class="fas fa-file"></i> Create File
                        </button>
                        <button class="action-btn create-btn" data-action="create-folder">
                          <i class="fas fa-folder"></i> Create Folder
                        </button>
                        <button class="action-btn upload-btn" data-action="upload">
                          <i class="fas fa-plus"></i> Upload File
                        </button>
                      </div>
                    </div>
  `
  if (files.length === 0) {
    fileListContent.innerHTML = footerEl;

    // Add upload button event
    document.querySelector("[data-action='upload']").addEventListener("click", showUploadModal);
    return;
  }

  let html = '';

  files.forEach(file => {
    const iconClass = file.type === "folder" ? "fa-folder" : getFileIcon(file.name);

    html += `
                    <div class="file-item" data-name="${file.name}" data-type="${file.type}" data-action="open">
                        <div class="file-name">
                            <div class="file-icon ${file.type === "folder" ? "folder-icon" : ""}">
                                <i class="fas ${iconClass}"></i>
                            </div>
                            <span>${file.name}</span>
                        </div>
                        <div class="file-size">${file.size}</div>
                        <div class="file-modified">${file.modified}</div>
                        <div class="file-actions">
                            <button class="action-btn" data-action="rename"><i class="fas fa-edit"></i> Rename</button>
                            <button class="action-btn delete-btn" data-action="delete"><i class="fas fa-trash"></i> Delete</button>
                        </div>
                    </div>
                `;
  });

  // Add upload button
  html += footerEl;

  fileListContent.innerHTML = html;

  // Add event listeners
  document.querySelectorAll("[data-action]").forEach(element => {
    element.addEventListener("click", handleFileAction);
  });
}

// Handle file actions
function handleFileAction(event) {
  const action = event.currentTarget.getAttribute("data-action");
  const fileItem = event.currentTarget.closest(".file-item");

  if (action === "upload") {
    showUploadModal();
    return;
  } else if (action === "create-file") {
    showCreateFileModal();
    return;
  } else if (action === "create-folder") {
    showCreateFolderModal();
    return;
  }

  const fileName = fileItem.getAttribute("data-name");
  const fileType = fileItem.getAttribute("data-type");

  currentFile = { name: fileName, type: fileType };
  currentAction = action;

  if (action === "open" && fileType === "folder") {
    const newPath = currentPath ? `${currentPath}/${fileName}` : fileName;
    currentPath = newPath;
    loadFiles(newPath);
  } else if (action === "open" && fileType === "file") {
    window.open(`/file/${currentPath}/${fileName}`);
  } else if (action === "rename") {
    showRenameModal(fileName);
    event.stopPropagation();
  } else if (action === "delete") {
    showConfirmModal(
      "Confirm Deletion",
      `Are you sure you want to delete this ${fileType === "folder" ? "folder" : "file"} "${fileName}"? This operation cannot be undone.`
    );
    event.stopPropagation();
  }
}

// Show upload dialog
function showUploadModal() {
  resetUploadForm();
  uploadModal.classList.add("active");
}

// Show create file dialog
function showCreateFileModal() {
  createFileInput.value = "";
  clearError(createFileError);
  createFileModal.classList.add("active");
  createFileInput.focus();
}

// Show create folder dialog
function showCreateFolderModal() {
  createFolderInput.value = "";
  clearError(createFolderError);
  createFolderModal.classList.add("active");
  createFolderInput.focus();
}

// Reset upload form
function resetUploadForm() {
  filesToUpload = [];
  uploadFileList.innerHTML = "";
  progressBar.style.display = "none";
  progressBar.style.width = "0%";
  progressBar.textContent = "0%";
  uploadStatus.textContent = "Ready to upload...";
  fileInput.value = "";
  isUploading = false;
}

// Handle file selection
function handleFileSelection(event) {
  const input = event.target;
  const files = Array.from(input.files);

  if (files.length === 0) return;

  filesToUpload = files;
  updateUploadFileList();
}

// Update upload file list
function updateUploadFileList() {
  uploadFileList.innerHTML = "";

  if (filesToUpload.length === 0) {
    uploadFileList.innerHTML = "<div style='padding: 10px; text-align: center; color: var(--light-text);'>No files selected</div>";
    return;
  }

  filesToUpload.forEach((file, index) => {
    const fileName = file.name;
    const fileSize = formatFileSize(file.size);

    const fileItem = document.createElement("div");
    fileItem.className = "upload-file-item";
    fileItem.innerHTML = `
                    <div class="upload-file-name" title="${fileName}">${fileName}</div>
                    <div class="upload-file-size">${fileSize}</div>
                `;

    uploadFileList.appendChild(fileItem);
  });

  uploadStatus.textContent = `${filesToUpload.length} files selected, ready to upload`;
}

// Start upload
function startUpload() {
  if (filesToUpload.length === 0) {
    showToast("Please select files to upload first", "warning");
    return;
  }

  isUploading = true;
  progressBar.style.display = "block";
  uploadStatus.textContent = "Uploading...";

  let progress = 0;
  const totalFiles = filesToUpload.length;
  let uploadedFiles = 0;
  const totalSize = filesToUpload.reduce((acc, file) => acc + file.size, 0);
  const uploadedSizes = Array(totalFiles).fill(0);

  for (let i = 0; i < totalFiles; i++) {
    const file = filesToUpload[i];
    const xhr = new XMLHttpRequest();
    xhr.open('POST', "/upload?dir=" + encodeURIComponent(currentPath) + "&filename=" + encodeURIComponent(file.name), true);
    xhr.setRequestHeader('Content-Type', 'application/octet-stream');

    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) {
        uploadedSizes[i] = e.loaded;
        progress = (uploadedSizes.reduce((acc, size) => acc + size, 0) / totalSize) * 100;
        progressBar.style.width = `${progress}%`;
        progressBar.textContent = `${Math.round(progress)}%`;
      }
    }

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        uploadedFiles++;
        if (uploadedFiles === totalFiles) {
          uploadStatus.textContent = "Upload completed!";
          showToast(`${totalFiles} files uploaded successfully`, "success");

          setTimeout(() => {
            uploadModal.classList.remove("active");
            loadFiles(currentPath);
            resetUploadForm();
          }, 1000);
        }
      } else {
        showError("Upload failed");
      }
    };
    xhr.send(file);
  }
}

// Show error message
function showError(message, errorElement) {
  errorElement.textContent = message;
  errorElement.previousElementSibling.classList.add("input-error");
}

// Clear error message
function clearError(errorElement) {
  errorElement.textContent = "";
  if (errorElement.previousElementSibling) {
    errorElement.previousElementSibling.classList.remove("input-error");
  }
}

// Format file size
function formatFileSize(bytes) {
  if (bytes === 0) return "0 Bytes";

  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
}

// Show loading status
function showLoading() {
  fileListContent.innerHTML = `
                <div class="loading">
                    <div class="loading-spinner"></div>
                    <span>Loading...</span>
                </div>
            `;
}

// Update breadcrumb navigation
function updateBreadcrumb(path) {
  breadcrumb.innerHTML = '<span class="breadcrumb-item active" data-path="">Documents</span>';

  if (!path) return;

  const parts = path.split("/");
  let current = "";

  parts.forEach((part, index) => {
    current = current ? `${current}/${part}` : part;
    const separator = '<span class="breadcrumb-separator">/</span>';

    breadcrumb.innerHTML += `
                    ${separator}
                    <span class="breadcrumb-item" data-path="${current}">${part}</span>
                `;
  });

  // Add breadcrumb events
  document.querySelectorAll(".breadcrumb-item").forEach(item => {
    item.addEventListener("click", () => {
      const path = item.getAttribute("data-path");
      currentPath = path;
      loadFiles(path);
    });
  });
}

// Show confirm dialog
function showConfirmModal(title, message) {
  confirmModalTitle.textContent = title;
  confirmModalMessage.textContent = message;
  confirmModal.classList.add("active");
}

// Show rename dialog
function showRenameModal(filename) {
  renameInput.value = filename;
  renameModal.classList.add("active");
  renameInput.focus();
}

// Delete file
function deleteFile() {
  showLoading();

  fetch("/delete", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      path: currentPath,
      file: currentFile.name,
    }),
  }).then(res => {
    if (!res.ok) {
      throw `Delete "${currentFile.name}" failed`
    }
    showToast(`Deleted ${currentFile.type === "folder" ? "folder" : "file"} "${currentFile.name}"`, "success");
    loadFiles(currentPath);
  }).catch(err => {
    showToast(err.message, "error");
  })
}

// Rename file
function renameFile() {
  const newName = renameInput.value.trim();

  if (!newName) {
    showToast("Name cannot be empty", "error");
    return;
  }

  if (newName === currentFile.name) {
    return;
  }

  showLoading();

  fetch("/rename", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      path: currentPath,
      file: currentFile.name,
      rename: newName
    }),
  }).then(res => {
    if (!res.ok) {
      throw new Error('Rename failed');
    }
    showToast(`Renamed "${currentFile.name}" to "${newName}"`, "success");
    loadFiles(currentPath);
  }).catch(err => {
    showToast(err.message, "error");
  })
}

// Create file
function createFile() {
  const filename = createFileInput.value.trim();

  showLoading();

  fetch('/create', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      path: currentPath,
      file: filename,
      type: "file"
    })
  })
    .then(res => {
      if (!res.ok) {
        throw new Error('File creation failed');
      }
      showToast(`File "${filename}" created successfully`, "success");
      loadFiles(currentPath);
    })
    .catch(err => {
      showToast(err.message, "error");
    });
}

// Create folder
function createFolder() {
  const foldername = createFolderInput.value.trim();

  showLoading();

  fetch('/create', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      path: currentPath,
      file: foldername,
      type: "folder"
    })
  })
    .then(res => {
      if (!res.ok) {
        throw new Error('Folder creation failed');
      } else {
        showToast(`Folder "${foldername}" created successfully`, "success");
        loadFiles(currentPath);
      }
    })
    .catch(err => {
      showToast(err.message, "error");
    });
}

// Validate name
function validateName(name, errorElement) {
  if (!name || name.trim() === "") {
    showError("Name cannot be empty", errorElement);
    return false;
  }

  // Check for special characters
  const specialChars = /[`!@#$%^&*()+\=\[\]{};':"\\|,<>\/?~]/;
  if (specialChars.test(name)) {
    showError("The name cannot contain special characters", errorElement);
    return false;
  }

  clearError(errorElement);
  return true;
}

// Show toast message
function showToast(message, type = "success") {
  toast.textContent = message;
  toast.className = "toast show " + type;

  setTimeout(() => {
    toast.classList.remove("show");
  }, 3000);
}

// Get file type icon
function getFileIcon(filename) {
  const extension = filename.split(".").pop().toLowerCase();

  switch (extension) {
    case "pdf":
      return "fa-file-pdf";
    case "doc":
    case "docx":
      return "fa-file-word";
    case "xls":
    case "xlsx":
      return "fa-file-excel";
    case "ppt":
    case "pptx":
      return "fa-file-powerpoint";
    case "jpg":
    case "jpeg":
    case "png":
    case "gif":
      return "fa-file-image";
    case "zip":
    case "rar":
    case "7z":
      return "fa-file-archive";
    case "txt":
      return "fa-file-alt";
    case "mp3":
    case "wav":
      return "fa-file-audio";
    case "mp4":
    case "avi":
    case "mov":
      return "fa-file-video";
    default:
      return "fa-file";
  }
}