import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Notification controller for real-time notifications
//
// Handles:
// - WebSocket subscription to NotificationChannel
// - Badge count updates
// - Toast notifications for new alerts
// - Dropdown toggle and listing
// - Mark as read functionality
//
export default class extends Controller {
  static targets = ["badge", "dropdown", "list", "emptyState", "toast", "toastMessage"]
  static values = {
    unreadCount: Number
  }

  connect() {
    this.isDropdownOpen = false

    // Subscribe to notification channel
    this.subscription = consumer.subscriptions.create(
      { channel: "NotificationChannel" },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        received: (data) => this.handleReceived(data)
      }
    )

    // Load initial notifications
    this.loadNotifications()

    // Bind click outside handler
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    document.removeEventListener('click', this.handleClickOutside)

    // Clear toast timeout
    if (this.toastTimeout) {
      clearTimeout(this.toastTimeout)
    }
  }

  // Called when WebSocket connects
  handleConnected() {
    console.log('Notifications connected')
  }

  // Called when WebSocket disconnects
  handleDisconnected() {
    console.log('Notifications disconnected')
  }

  // Handle incoming WebSocket messages
  handleReceived(data) {
    switch (data.type) {
      case 'new_notification':
        this.handleNewNotification(data)
        break
      case 'notification_read':
        this.updateBadge(data.unread_count)
        this.markNotificationRead(data.notification_id)
        break
      case 'notifications_read':
        this.updateBadge(0)
        this.markAllNotificationsRead()
        break
    }
  }

  // Handle new notification
  handleNewNotification(data) {
    // Update badge
    this.updateBadge(data.unread_count)

    // Show toast notification
    this.showToast(data.notification)

    // Add to dropdown list if open
    if (this.isDropdownOpen) {
      this.prependNotification(data.notification)
    }
  }

  // Load notifications from server
  async loadNotifications() {
    try {
      const response = await fetch('/notifications', {
        headers: { 'Accept': 'application/json' }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateBadge(data.unread_count)
        this.renderNotifications(data.notifications)
      }
    } catch (error) {
      console.error('Failed to load notifications:', error)
    }
  }

  // Update badge count
  updateBadge(count) {
    this.unreadCountValue = count

    if (this.hasBadgeTarget) {
      if (count > 0) {
        this.badgeTarget.textContent = count > 99 ? '99+' : count
        this.badgeTarget.classList.remove('hidden')
      } else {
        this.badgeTarget.classList.add('hidden')
      }
    }
  }

  // Toggle dropdown
  toggleDropdown(event) {
    event.stopPropagation()

    if (this.isDropdownOpen) {
      this.closeDropdown()
    } else {
      this.openDropdown()
    }
  }

  // Open dropdown
  openDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.remove('hidden')
      this.isDropdownOpen = true
      // Refresh notifications when opening
      this.loadNotifications()
    }
  }

  // Close dropdown
  closeDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
      this.isDropdownOpen = false
    }
  }

  // Handle click outside
  handleClickOutside(event) {
    if (this.isDropdownOpen && !this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  // Render notifications list
  renderNotifications(notifications) {
    if (!this.hasListTarget) return

    if (notifications.length === 0) {
      if (this.hasEmptyStateTarget) {
        this.emptyStateTarget.classList.remove('hidden')
      }
      this.listTarget.innerHTML = ''
      return
    }

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add('hidden')
    }

    this.listTarget.innerHTML = notifications.map(n => this.notificationHtml(n)).join('')
  }

  // Prepend new notification to list
  prependNotification(notification) {
    if (!this.hasListTarget) return

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add('hidden')
    }

    const html = this.notificationHtml(notification)
    this.listTarget.insertAdjacentHTML('afterbegin', html)
  }

  // Generate notification HTML
  notificationHtml(n) {
    const avatarHtml = n.actor_avatar_url
      ? `<img src="${n.actor_avatar_url}" class="w-10 h-10 rounded-full object-cover" alt="">`
      : `<div class="w-10 h-10 rounded-full bg-theme-primary/20 flex items-center justify-center text-sm font-medium text-theme-primary">${n.actor_name[0]}</div>`

    const icon = n.notification_type === 'mention'
      ? `<svg class="w-4 h-4 text-theme-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207"></path></svg>`
      : `<svg class="w-4 h-4 text-theme-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"></path></svg>`

    return `
      <a href="/chats/${n.chat_id}#message_${n.message_id}"
         class="notification-item block px-4 py-3 hover:bg-theme-secondary/30 transition-colors ${n.read ? 'opacity-60' : ''}"
         data-notification-id="${n.id}"
         data-action="click->notification#handleClick">
        <div class="flex items-start gap-3">
          <div class="relative flex-shrink-0">
            ${avatarHtml}
            <div class="absolute -bottom-1 -right-1 p-0.5 bg-theme-base rounded-full">
              ${icon}
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm ${n.read ? 'text-theme-text-muted' : 'text-theme-text font-medium'}">${n.description}</p>
            <p class="text-xs text-theme-text-muted mt-0.5">${n.time_ago}</p>
          </div>
          ${!n.read ? '<div class="w-2 h-2 rounded-full bg-theme-primary flex-shrink-0 mt-2"></div>' : ''}
        </div>
      </a>
    `
  }

  // Handle notification click
  handleClick(event) {
    const notificationItem = event.currentTarget
    const notificationId = notificationItem.dataset.notificationId

    // Mark as read via API
    if (notificationId) {
      this.markAsRead(notificationId)
    }

    this.closeDropdown()
  }

  // Mark single notification as read
  async markAsRead(notificationId) {
    try {
      await fetch(`/notifications/${notificationId}/mark_read`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        }
      })
    } catch (error) {
      console.error('Failed to mark notification as read:', error)
    }
  }

  // Mark all notifications as read
  async markAllRead(event) {
    event.preventDefault()
    event.stopPropagation()

    try {
      const response = await fetch('/notifications/mark_all_read', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        }
      })

      if (response.ok) {
        this.updateBadge(0)
        this.markAllNotificationsRead()
      }
    } catch (error) {
      console.error('Failed to mark all as read:', error)
    }
  }

  // Update UI to show notification as read
  markNotificationRead(notificationId) {
    const item = this.element.querySelector(`[data-notification-id="${notificationId}"]`)
    if (item) {
      item.classList.add('opacity-60')
      const unreadDot = item.querySelector('.bg-theme-primary.w-2.h-2')
      if (unreadDot) unreadDot.remove()
    }
  }

  // Update UI to show all notifications as read
  markAllNotificationsRead() {
    const items = this.element.querySelectorAll('.notification-item')
    items.forEach(item => {
      item.classList.add('opacity-60')
      const unreadDot = item.querySelector('.bg-theme-primary.w-2.h-2')
      if (unreadDot) unreadDot.remove()
    })
  }

  // Show toast notification
  showToast(notification) {
    if (!this.hasToastTarget || !this.hasToastMessageTarget) return

    // Set message
    this.toastMessageTarget.textContent = notification.description

    // Show toast
    this.toastTarget.classList.remove('hidden', 'translate-y-full', 'opacity-0')
    this.toastTarget.classList.add('translate-y-0', 'opacity-100')

    // Clear existing timeout
    if (this.toastTimeout) {
      clearTimeout(this.toastTimeout)
    }

    // Auto-hide after 4 seconds
    this.toastTimeout = setTimeout(() => {
      this.hideToast()
    }, 4000)
  }

  // Hide toast notification
  hideToast() {
    if (!this.hasToastTarget) return

    this.toastTarget.classList.add('translate-y-full', 'opacity-0')
    this.toastTarget.classList.remove('translate-y-0', 'opacity-100')

    // Fully hide after animation
    setTimeout(() => {
      this.toastTarget.classList.add('hidden')
    }, 300)
  }

  // Dismiss toast on click
  dismissToast() {
    if (this.toastTimeout) {
      clearTimeout(this.toastTimeout)
    }
    this.hideToast()
  }
}
