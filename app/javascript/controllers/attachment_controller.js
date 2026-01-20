import { Controller } from "@hotwired/stimulus"

// Attachment controller for handling file uploads in messages
//
// Handles:
// - File selection via button click
// - File previews (images as thumbnails, files as icons)
// - Removing individual files before upload
// - Clearing files after form submission
// - Drag and drop support
//
export default class extends Controller {
  static targets = ["input", "preview", "button", "count"]
  static values = {
    maxSize: { type: Number, default: 104857600 }, // 100MB in bytes
    maxFiles: { type: Number, default: 10 }
  }

  connect() {
    this.files = new DataTransfer()
    this.updateUI()
  }

  // Trigger file input click
  selectFiles() {
    this.inputTarget.click()
  }

  // Handle file input change
  filesSelected(event) {
    const newFiles = Array.from(event.target.files)

    for (const file of newFiles) {
      // Check file size
      if (file.size > this.maxSizeValue) {
        alert(`${file.name} is too large. Maximum size is ${this.formatFileSize(this.maxSizeValue)}.`)
        continue
      }

      // Check max files
      if (this.files.files.length >= this.maxFilesValue) {
        alert(`Maximum ${this.maxFilesValue} files allowed.`)
        break
      }

      // Add file to our DataTransfer
      this.files.items.add(file)
    }

    // Update the input's files
    this.inputTarget.files = this.files.files
    this.updateUI()
  }

  // Remove a specific file
  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    const newFiles = new DataTransfer()

    for (let i = 0; i < this.files.files.length; i++) {
      if (i !== index) {
        newFiles.items.add(this.files.files[i])
      }
    }

    this.files = newFiles
    this.inputTarget.files = this.files.files
    this.updateUI()
  }

  // Clear all files (called after form submission)
  clear() {
    this.files = new DataTransfer()
    this.inputTarget.files = this.files.files
    this.updateUI()
  }

  // Handle drag over
  dragOver(event) {
    event.preventDefault()
    event.currentTarget.classList.add('drag-over')
  }

  // Handle drag leave
  dragLeave(event) {
    event.currentTarget.classList.remove('drag-over')
  }

  // Handle drop
  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove('drag-over')

    const droppedFiles = Array.from(event.dataTransfer.files)

    for (const file of droppedFiles) {
      if (file.size > this.maxSizeValue) {
        alert(`${file.name} is too large. Maximum size is ${this.formatFileSize(this.maxSizeValue)}.`)
        continue
      }

      if (this.files.files.length >= this.maxFilesValue) {
        alert(`Maximum ${this.maxFilesValue} files allowed.`)
        break
      }

      this.files.items.add(file)
    }

    this.inputTarget.files = this.files.files
    this.updateUI()
  }

  // Update the UI based on current files
  updateUI() {
    this.renderPreviews()
    this.updateCount()
    this.updateButtonState()
  }

  // Render file previews
  renderPreviews() {
    if (!this.hasPreviewTarget) return

    if (this.files.files.length === 0) {
      this.previewTarget.classList.add('hidden')
      this.previewTarget.innerHTML = ''
      return
    }

    this.previewTarget.classList.remove('hidden')

    let html = '<div class="flex flex-wrap gap-2">'

    for (let i = 0; i < this.files.files.length; i++) {
      const file = this.files.files[i]
      html += this.renderFilePreview(file, i)
    }

    html += '</div>'
    this.previewTarget.innerHTML = html
  }

  // Render a single file preview
  renderFilePreview(file, index) {
    const isImage = file.type.startsWith('image/')
    const isVideo = file.type.startsWith('video/')

    if (isImage) {
      return this.renderImagePreview(file, index)
    } else if (isVideo) {
      return this.renderVideoPreview(file, index)
    } else {
      return this.renderDocumentPreview(file, index)
    }
  }

  // Render image preview with thumbnail
  renderImagePreview(file, index) {
    const url = URL.createObjectURL(file)
    return `
      <div class="relative group">
        <img src="${url}" alt="${this.escapeHtml(file.name)}"
             class="w-16 h-16 object-cover rounded-lg border border-theme-border"
             onload="URL.revokeObjectURL(this.src)">
        <button type="button"
                data-action="click->attachment#removeFile"
                data-index="${index}"
                class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                title="Remove">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    `
  }

  // Render video preview
  renderVideoPreview(file, index) {
    return `
      <div class="relative group">
        <div class="w-16 h-16 bg-theme-surface rounded-lg border border-theme-border flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-theme-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
        </div>
        <button type="button"
                data-action="click->attachment#removeFile"
                data-index="${index}"
                class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                title="Remove">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
        <div class="absolute bottom-0 left-0 right-0 bg-black/50 text-white text-[10px] px-1 py-0.5 rounded-b-lg truncate">
          ${this.escapeHtml(this.truncateFilename(file.name, 10))}
        </div>
      </div>
    `
  }

  // Render document preview
  renderDocumentPreview(file, index) {
    const icon = this.getDocumentIcon(file.type)
    return `
      <div class="relative group">
        <div class="w-16 h-16 bg-theme-surface rounded-lg border border-theme-border flex flex-col items-center justify-center p-1">
          ${icon}
          <span class="text-[9px] text-theme-secondary mt-1 truncate w-full text-center">${this.escapeHtml(this.truncateFilename(file.name, 8))}</span>
        </div>
        <button type="button"
                data-action="click->attachment#removeFile"
                data-index="${index}"
                class="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-600"
                title="Remove">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    `
  }

  // Get appropriate icon for document type
  getDocumentIcon(mimeType) {
    if (mimeType === 'application/pdf') {
      return `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
      </svg>`
    }

    // Default document icon
    return `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-theme-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    </svg>`
  }

  // Update file count badge
  updateCount() {
    if (!this.hasCountTarget) return

    const count = this.files.files.length
    if (count > 0) {
      this.countTarget.textContent = count
      this.countTarget.classList.remove('hidden')
    } else {
      this.countTarget.classList.add('hidden')
    }
  }

  // Update button state
  updateButtonState() {
    if (!this.hasButtonTarget) return

    const hasFiles = this.files.files.length > 0
    if (hasFiles) {
      this.buttonTarget.classList.add('text-theme-primary')
    } else {
      this.buttonTarget.classList.remove('text-theme-primary')
    }
  }

  // Format file size to human readable
  formatFileSize(bytes) {
    if (bytes === 0) return '0 B'
    const units = ['B', 'KB', 'MB', 'GB']
    const exp = Math.floor(Math.log(bytes) / Math.log(1024))
    return `${(bytes / Math.pow(1024, exp)).toFixed(1)} ${units[exp]}`
  }

  // Truncate filename
  truncateFilename(name, maxLength) {
    if (name.length <= maxLength) return name
    const ext = name.split('.').pop()
    const base = name.slice(0, name.length - ext.length - 1)
    const truncated = base.slice(0, maxLength - ext.length - 3)
    return `${truncated}...${ext}`
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
