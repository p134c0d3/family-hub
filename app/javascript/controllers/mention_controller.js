import { Controller } from "@hotwired/stimulus"

// Mention controller for @mention autocomplete in chat messages
//
// Handles:
// - Detecting @ character in input
// - Fetching matching users via API
// - Displaying autocomplete dropdown
// - Keyboard navigation (up/down/enter/escape)
// - Inserting selected mention into input
//
export default class extends Controller {
  static targets = ["input", "dropdown", "results"]
  static values = {
    chatId: Number,
    url: String
  }

  connect() {
    this.selectedIndex = -1
    this.mentionStart = -1
    this.isOpen = false
    this.members = []

    // Bind event handlers
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleInput = this.handleInput.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)

    // Add event listeners
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('keydown', this.handleKeydown)
      this.inputTarget.addEventListener('input', this.handleInput)
    }

    document.addEventListener('click', this.handleClickOutside)
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener('keydown', this.handleKeydown)
      this.inputTarget.removeEventListener('input', this.handleInput)
    }
    document.removeEventListener('click', this.handleClickOutside)

    // Clear any pending fetch
    if (this.fetchTimeout) {
      clearTimeout(this.fetchTimeout)
    }
  }

  // Handle input changes - detect @ mentions
  handleInput(event) {
    const input = this.inputTarget
    const value = input.value
    const cursorPos = input.selectionStart

    // Find if we're in a mention (@ followed by letters, no space before @)
    const textBeforeCursor = value.substring(0, cursorPos)
    const mentionMatch = textBeforeCursor.match(/(^|\s)@([A-Za-z]*)$/)

    if (mentionMatch) {
      const query = mentionMatch[2]
      this.mentionStart = cursorPos - query.length - 1 // Position of @

      // Debounce the API call
      if (this.fetchTimeout) {
        clearTimeout(this.fetchTimeout)
      }

      this.fetchTimeout = setTimeout(() => {
        this.fetchMembers(query)
      }, 150)
    } else {
      this.closeDropdown()
    }
  }

  // Handle keydown for navigation
  handleKeydown(event) {
    if (!this.isOpen) return

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectNext()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectPrevious()
        break
      case 'Enter':
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          this.insertMention(this.members[this.selectedIndex])
        }
        break
      case 'Escape':
        event.preventDefault()
        this.closeDropdown()
        break
      case 'Tab':
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          this.insertMention(this.members[this.selectedIndex])
        } else if (this.members.length > 0) {
          event.preventDefault()
          this.insertMention(this.members[0])
        }
        break
    }
  }

  // Click outside to close dropdown
  handleClickOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  // Fetch members matching query
  async fetchMembers(query) {
    const url = this.urlValue || `/chats/${this.chatIdValue}/mentions`

    try {
      const response = await fetch(`${url}?query=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        this.members = await response.json()
        if (this.members.length > 0) {
          this.showDropdown()
        } else {
          this.closeDropdown()
        }
      }
    } catch (error) {
      console.error('Failed to fetch mentions:', error)
      this.closeDropdown()
    }
  }

  // Show dropdown with results
  showDropdown() {
    if (!this.hasDropdownTarget || !this.hasResultsTarget) return

    this.selectedIndex = 0
    this.isOpen = true

    // Build results HTML
    const html = this.members.map((member, index) => `
      <button type="button"
              class="mention-item w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-theme-secondary/50 ${index === this.selectedIndex ? 'bg-theme-secondary/50' : ''}"
              data-index="${index}"
              data-action="click->mention#selectItem">
        ${member.avatar_url
          ? `<img src="${member.avatar_url}" class="w-8 h-8 rounded-full object-cover" alt="">`
          : `<div class="w-8 h-8 rounded-full bg-theme-primary/20 flex items-center justify-center text-sm font-medium text-theme-primary">${member.initials}</div>`
        }
        <div class="flex flex-col">
          <span class="text-sm font-medium text-theme-text">${member.first_name}</span>
          <span class="text-xs text-theme-text-muted">${member.full_name}</span>
        </div>
      </button>
    `).join('')

    this.resultsTarget.innerHTML = html
    this.dropdownTarget.classList.remove('hidden')

    // Position dropdown near the cursor
    this.positionDropdown()
  }

  // Position dropdown near the text input
  positionDropdown() {
    if (!this.hasDropdownTarget || !this.hasInputTarget) return

    // Get input position
    const inputRect = this.inputTarget.getBoundingClientRect()

    // Position dropdown above the input
    this.dropdownTarget.style.bottom = 'calc(100% + 4px)'
    this.dropdownTarget.style.left = '0'
  }

  // Close dropdown
  closeDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
    }
    this.isOpen = false
    this.selectedIndex = -1
    this.members = []
  }

  // Select next item
  selectNext() {
    if (this.members.length === 0) return

    this.selectedIndex = (this.selectedIndex + 1) % this.members.length
    this.updateSelection()
  }

  // Select previous item
  selectPrevious() {
    if (this.members.length === 0) return

    this.selectedIndex = this.selectedIndex <= 0
      ? this.members.length - 1
      : this.selectedIndex - 1
    this.updateSelection()
  }

  // Update visual selection
  updateSelection() {
    if (!this.hasResultsTarget) return

    const items = this.resultsTarget.querySelectorAll('.mention-item')
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-theme-secondary/50')
      } else {
        item.classList.remove('bg-theme-secondary/50')
      }
    })
  }

  // Handle item click
  selectItem(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    if (!isNaN(index) && this.members[index]) {
      this.insertMention(this.members[index])
    }
  }

  // Insert selected mention into input
  insertMention(member) {
    if (!this.hasInputTarget) return

    const input = this.inputTarget
    const value = input.value
    const cursorPos = input.selectionStart

    // Replace @query with @FirstName
    const beforeMention = value.substring(0, this.mentionStart)
    const afterMention = value.substring(cursorPos)

    // Insert mention with a trailing space
    const mention = `@${member.first_name} `
    input.value = beforeMention + mention + afterMention

    // Move cursor after the inserted mention
    const newCursorPos = beforeMention.length + mention.length
    input.setSelectionRange(newCursorPos, newCursorPos)

    // Close dropdown
    this.closeDropdown()

    // Focus input
    input.focus()

    // Trigger input event so other controllers can react
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }
}
