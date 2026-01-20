import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Chat list controller for the chat sidebar
//
// Handles:
// - Active state management when a chat is selected
// - Real-time typing indicators in the chat list
//
// Subscribes to each chat the user is a member of and displays
// typing indicators instead of the last message when someone is typing.
//
export default class extends Controller {
  static targets = ["chatItem"]
  static values = {
    currentUserId: Number
  }

  connect() {
    this.subscriptions = new Map()
    this.typingUsers = new Map() // chatId -> Map of userId -> { name, timeout }

    // Subscribe to each chat
    this.chatItemTargets.forEach((item) => {
      const chatId = parseInt(item.dataset.chatId, 10)
      if (chatId) {
        this.subscribeToChat(chatId)
      }
    })

    // Listen for Turbo Frame loads to update active state
    document.addEventListener('turbo:frame-load', this.handleFrameLoad.bind(this))

    // Handle click events on chat items for active state
    this.element.addEventListener('click', this.handleChatClick.bind(this))
  }

  disconnect() {
    // Unsubscribe from all chats
    this.subscriptions.forEach((subscription) => {
      subscription.unsubscribe()
    })
    this.subscriptions.clear()

    // Clear all typing timeouts
    this.typingUsers.forEach((chatTyping) => {
      chatTyping.forEach((entry) => {
        if (entry.timeout) clearTimeout(entry.timeout)
      })
    })
    this.typingUsers.clear()

    // Remove event listeners
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad.bind(this))
  }

  // Handle click on a chat item to set it as active
  handleChatClick(event) {
    const chatItem = event.target.closest('[data-chat-list-target="chatItem"]')
    if (!chatItem) return

    this.setActiveChat(chatItem)
  }

  // Handle Turbo Frame loads to sync active state with URL
  handleFrameLoad(event) {
    if (event.target.id !== 'chat_conversation') return

    // Extract chat ID from the current URL (supports both /chats?active_chat=123 and /chats/123)
    const urlParams = new URLSearchParams(window.location.search)
    const activeChatParam = urlParams.get('active_chat')
    const pathMatch = window.location.pathname.match(/\/chats\/(\d+)/)

    const chatId = activeChatParam ? parseInt(activeChatParam, 10) : (pathMatch ? parseInt(pathMatch[1], 10) : null)

    if (chatId) {
      const chatItem = this.chatItemTargets.find(
        (item) => parseInt(item.dataset.chatId, 10) === chatId
      )
      if (chatItem) {
        this.setActiveChat(chatItem)
      }
    }
  }

  // Update the visual active state and clear unread badge
  setActiveChat(activeItem) {
    // Remove active state from all items
    this.chatItemTargets.forEach((item) => {
      item.classList.remove('bg-theme-primary/10')
      item.classList.add('hover:bg-theme-surface/80')
    })

    // Add active state to the selected item
    if (activeItem) {
      activeItem.classList.add('bg-theme-primary/10')
      activeItem.classList.remove('hover:bg-theme-surface/80')

      // Hide the unread badge since the user is now viewing this chat
      // The server marks it as read, but the badge is outside the Turbo Frame
      const unreadBadge = activeItem.querySelector('[data-unread-badge]')
      if (unreadBadge) {
        unreadBadge.remove()
      }
    }
  }

  subscribeToChat(chatId) {
    if (this.subscriptions.has(chatId)) return

    const subscription = consumer.subscriptions.create(
      { channel: "ChatChannel", chat_id: chatId },
      {
        received: (data) => this.handleReceived(chatId, data)
      }
    )

    this.subscriptions.set(chatId, subscription)
    this.typingUsers.set(chatId, new Map())
  }

  handleReceived(chatId, data) {
    switch (data.type) {
      case 'typing':
        this.handleTypingIndicator(chatId, data)
        break
      case 'message_preview':
        this.handleMessagePreview(chatId, data)
        break
    }
  }

  // Handle new message preview update
  handleMessagePreview(chatId, data) {
    const chatItem = this.chatItemTargets.find(
      (item) => parseInt(item.dataset.chatId, 10) === chatId
    )
    if (!chatItem) return

    const previewElement = chatItem.querySelector('[data-chat-preview]')
    if (!previewElement) return

    // Build the preview text
    const isOwnMessage = data.sender_id === this.currentUserIdValue
    const senderLabel = isOwnMessage ? 'You' : data.sender_name
    const previewText = data.preview || '📎 Attachment'

    // Update the preview HTML
    previewElement.innerHTML = `
      <p class="text-xs text-theme-secondary truncate">
        <span class="text-theme-text">${senderLabel}:</span>
        ${this.escapeHtml(previewText)}
      </p>
    `

    // Update timestamp if visible
    const timestampElement = chatItem.querySelector('.text-\\[10px\\]')
    if (timestampElement) {
      timestampElement.textContent = 'just now'
    }

    // Show unread badge for messages from others (if chat is not currently active)
    if (!isOwnMessage && !chatItem.classList.contains('bg-theme-primary/10')) {
      this.showUnreadBadge(chatItem)
    }
  }

  // Show or increment unread badge
  showUnreadBadge(chatItem) {
    let badge = chatItem.querySelector('[data-unread-badge]')
    if (badge) {
      // Increment existing badge
      const currentCount = parseInt(badge.textContent, 10) || 0
      const newCount = currentCount + 1
      badge.textContent = newCount > 99 ? '99+' : newCount
    } else {
      // Create new badge
      const container = chatItem.querySelector('.flex.items-center.gap-3')
      if (container) {
        badge = document.createElement('div')
        badge.setAttribute('data-unread-badge', '')
        badge.className = 'flex-shrink-0 w-5 h-5 rounded-full bg-theme-primary text-white text-[10px] flex items-center justify-center font-medium'
        badge.textContent = '1'
        container.appendChild(badge)
      }
    }
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  handleTypingIndicator(chatId, data) {
    if (data.user_id === this.currentUserIdValue) return

    const chatTyping = this.typingUsers.get(chatId)
    if (!chatTyping) return

    // Clear existing timeout for this user
    const existingEntry = chatTyping.get(data.user_id)
    if (existingEntry && existingEntry.timeout) {
      clearTimeout(existingEntry.timeout)
    }

    if (data.is_typing) {
      // Set timeout to auto-remove after 5 seconds
      const timeout = setTimeout(() => {
        chatTyping.delete(data.user_id)
        this.updateChatItem(chatId)
      }, 5000)

      chatTyping.set(data.user_id, { name: data.user_name, timeout })
    } else {
      chatTyping.delete(data.user_id)
    }

    this.updateChatItem(chatId)
  }

  updateChatItem(chatId) {
    const chatItem = this.chatItemTargets.find(
      (item) => parseInt(item.dataset.chatId, 10) === chatId
    )
    if (!chatItem) return

    const chatTyping = this.typingUsers.get(chatId)
    const previewElement = chatItem.querySelector('[data-chat-preview]')
    const typingElement = chatItem.querySelector('[data-chat-typing]')

    if (!previewElement || !typingElement) return

    const typingNames = chatTyping ? Array.from(chatTyping.values()).map(u => u.name) : []

    if (typingNames.length === 0) {
      // Show normal preview
      previewElement.classList.remove('hidden')
      typingElement.classList.add('hidden')
    } else {
      // Show typing indicator
      let text
      if (typingNames.length === 1) {
        text = `${typingNames[0]} is typing...`
      } else if (typingNames.length === 2) {
        text = `${typingNames[0]} and ${typingNames[1]} are typing...`
      } else {
        text = `${typingNames.length} people are typing...`
      }

      typingElement.querySelector('.typing-text').textContent = text
      previewElement.classList.add('hidden')
      typingElement.classList.remove('hidden')
    }
  }
}
