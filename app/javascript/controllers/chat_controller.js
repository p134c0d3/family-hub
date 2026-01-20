import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Chat controller for real-time messaging UI
//
// Handles:
// - WebSocket subscription to chat channel
// - Auto-scroll to new messages
// - Typing indicators
// - Message input handling
// - Reply to messages
//
export default class extends Controller {
  static targets = ["messages", "messageInput", "typingIndicator", "sendButton", "replyIndicator", "parentMessageId", "replyAuthor", "replyContent"]
  static values = {
    chatId: Number,
    currentUserId: Number
  }

  connect() {
    this.typingTimeout = null
    this.isTyping = false
    this.typingUsers = new Map() // Track who's typing

    // Subscribe to the chat channel
    this.subscription = consumer.subscriptions.create(
      { channel: "ChatChannel", chat_id: this.chatIdValue },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        received: (data) => this.handleReceived(data)
      }
    )

    // Scroll to bottom on load - use multiple strategies to ensure it works
    this.scrollToBottom()

    // Also scroll after a short delay to handle images loading
    setTimeout(() => this.scrollToBottom(), 100)
    setTimeout(() => this.scrollToBottom(), 500)

    // Wait for all images to load, then scroll again
    this.waitForImagesToLoad().then(() => this.scrollToBottom())

    // Set up MutationObserver to detect new messages added via Turbo Streams
    this.setupMessageObserver()

    // Focus the input
    if (this.hasMessageInputTarget) {
      this.messageInputTarget.focus()
    }
  }

  // Observe the messages container for new messages added via Turbo Streams
  setupMessageObserver() {
    if (!this.hasMessagesTarget) return

    // Find the actual #messages div where messages are appended
    const messagesContainer = this.messagesTarget.querySelector('#messages')
    if (!messagesContainer) return

    this.messageObserver = new MutationObserver((mutations) => {
      let hasNewMessages = false

      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          // Check if any added nodes are actual message elements
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE &&
                (node.id?.startsWith('message_') || node.querySelector?.('[id^="message_"]'))) {
              hasNewMessages = true
            }
          })
        }
      })

      if (hasNewMessages) {
        // Small delay to allow images to start loading, then scroll
        setTimeout(() => this.scrollToBottom(), 50)

        // Also wait for any new images in the message to load
        this.waitForImagesToLoad().then(() => this.scrollToBottom())
      }
    })

    this.messageObserver.observe(messagesContainer, {
      childList: true,
      subtree: true
    })
  }

  // Wait for all images in the messages area to load
  async waitForImagesToLoad() {
    if (!this.hasMessagesTarget) return

    const images = this.messagesTarget.querySelectorAll('img')
    const promises = Array.from(images).map(img => {
      if (img.complete) return Promise.resolve()
      return new Promise(resolve => {
        img.addEventListener('load', resolve, { once: true })
        img.addEventListener('error', resolve, { once: true })
      })
    })

    return Promise.all(promises)
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    }
    if (this.typingInterval) {
      clearInterval(this.typingInterval)
    }
    // Clear all typing user timeouts
    this.typingUsers.forEach((entry) => {
      if (entry && entry.timeout) clearTimeout(entry.timeout)
    })
    // Disconnect the message observer
    if (this.messageObserver) {
      this.messageObserver.disconnect()
    }
  }

  // Called when WebSocket connects
  handleConnected() {
    console.log('Chat connected')
  }

  // Called when WebSocket disconnects
  handleDisconnected() {
    console.log('Chat disconnected')
  }

  // Handle incoming WebSocket messages
  handleReceived(data) {
    switch (data.type) {
      case 'typing':
        this.handleTypingIndicator(data)
        break
      default:
        // Turbo Streams handle message updates
        this.scrollToBottom()
    }
  }

  // Handle typing indicator from other users
  handleTypingIndicator(data) {
    if (data.user_id === this.currentUserIdValue) return

    // Clear existing timeout for this user
    const existingEntry = this.typingUsers.get(data.user_id)
    if (existingEntry && existingEntry.timeout) {
      clearTimeout(existingEntry.timeout)
    }

    if (data.is_typing) {
      // Set timeout to auto-remove after 5 seconds (gives buffer for network latency)
      const timeout = setTimeout(() => {
        this.typingUsers.delete(data.user_id)
        this.updateTypingIndicator()
      }, 5000)

      this.typingUsers.set(data.user_id, { name: data.user_name, timeout })
    } else {
      this.typingUsers.delete(data.user_id)
    }

    this.updateTypingIndicator()
  }

  // Update the typing indicator UI
  updateTypingIndicator() {
    if (!this.hasTypingIndicatorTarget) return

    const typingNames = Array.from(this.typingUsers.values()).map(u => u.name)

    if (typingNames.length === 0) {
      this.typingIndicatorTarget.classList.add('hidden')
    } else {
      let text
      if (typingNames.length === 1) {
        text = `${typingNames[0]} is typing...`
      } else if (typingNames.length === 2) {
        text = `${typingNames[0]} and ${typingNames[1]} are typing...`
      } else {
        text = `${typingNames.length} people are typing...`
      }

      const textSpan = this.typingIndicatorTarget.querySelector('.typing-text')
      if (textSpan) {
        textSpan.textContent = text
      }
      this.typingIndicatorTarget.classList.remove('hidden')
    }
  }

  // Handle input changes for typing indicator
  inputChanged() {
    // Send typing status immediately and set up continuous sending
    if (!this.isTyping) {
      this.isTyping = true
      this.sendTypingStatus(true)

      // Set up interval to keep sending typing status while user types
      this.typingInterval = setInterval(() => {
        if (this.isTyping) {
          this.sendTypingStatus(true)
        }
      }, 3000) // Re-send every 3 seconds to keep indicator alive
    }

    // Clear previous stop timeout
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    }

    // Set timeout to stop typing indicator after user stops typing
    this.typingTimeout = setTimeout(() => {
      this.isTyping = false
      this.sendTypingStatus(false)

      // Clear the interval
      if (this.typingInterval) {
        clearInterval(this.typingInterval)
        this.typingInterval = null
      }
    }, 2000)
  }

  // Send typing status via ActionCable
  sendTypingStatus(isTyping) {
    if (this.subscription) {
      this.subscription.perform('typing', { is_typing: isTyping })
    }
  }

  // Handle form submission
  submitMessage(event) {
    // Stop typing indicator
    if (this.isTyping) {
      this.isTyping = false
      this.sendTypingStatus(false)
    }

    // Clear the timeout
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    }
  }

  // Clear input after successful submission (called by Turbo)
  clearInput() {
    if (this.hasMessageInputTarget) {
      this.messageInputTarget.value = ''
      this.messageInputTarget.focus()
    }

    // Clear reply state
    this.cancelReply()
  }

  // Start replying to a message
  startReply(event) {
    const messageId = event.currentTarget.dataset.messageId
    const authorName = event.currentTarget.dataset.messageAuthor
    const messageContent = event.currentTarget.dataset.messageContent || ''
    const hasAttachments = event.currentTarget.dataset.messageHasAttachments === 'true'

    if (this.hasReplyIndicatorTarget && this.hasParentMessageIdTarget) {
      this.parentMessageIdTarget.value = messageId
      this.replyIndicatorTarget.classList.remove('hidden')

      // Update author
      if (this.hasReplyAuthorTarget) {
        this.replyAuthorTarget.textContent = authorName
      }

      // Update content preview
      if (this.hasReplyContentTarget) {
        if (messageContent) {
          this.replyContentTarget.textContent = messageContent
        } else if (hasAttachments) {
          this.replyContentTarget.textContent = '📎 Attachment'
        } else {
          this.replyContentTarget.textContent = ''
        }
      }
    }

    // Focus the input
    if (this.hasMessageInputTarget) {
      this.messageInputTarget.focus()
    }
  }

  // Cancel replying
  cancelReply() {
    if (this.hasReplyIndicatorTarget && this.hasParentMessageIdTarget) {
      this.parentMessageIdTarget.value = ''
      this.replyIndicatorTarget.classList.add('hidden')

      // Clear the preview
      if (this.hasReplyAuthorTarget) {
        this.replyAuthorTarget.textContent = ''
      }
      if (this.hasReplyContentTarget) {
        this.replyContentTarget.textContent = ''
      }
    }
  }

  // Handle Enter key in message input
  // Enter = send message, Shift+Enter = new line
  handleEnter(event) {
    // If Shift is held, allow default behavior (new line)
    if (event.shiftKey) {
      return
    }

    // Otherwise, prevent default and submit the form
    event.preventDefault()

    // Only submit if there's content or attachments
    const input = this.messageInputTarget
    const form = input.closest('form')

    if (input.value.trim() || form.querySelector('input[type="file"]')?.files?.length > 0) {
      // Check if there are attachments in the preview (attachment controller manages files)
      const hasAttachments = form.querySelector('[data-attachment-target="preview"]')?.children.length > 0

      if (input.value.trim() || hasAttachments) {
        form.requestSubmit()
      }
    }
  }

  // Scroll to the bottom of the messages
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      // Use requestAnimationFrame to ensure DOM is updated
      requestAnimationFrame(() => {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      })
    }
  }

  // Scroll to a specific message
  scrollToMessage(messageId) {
    const message = document.getElementById(`message_${messageId}`)
    if (message) {
      message.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }
}
