import { Controller } from "@hotwired/stimulus"

/**
 * Theme Controller
 *
 * Manages dark/light mode switching with three modes:
 * - 'light': Always light mode
 * - 'dark': Always dark mode
 * - 'system': Follow system preference
 *
 * The theme preference is stored in localStorage and synced with the server
 * when the user changes it (if logged in).
 */
export default class extends Controller {
  static values = {
    colorMode: { type: String, default: 'system' }
  }

  connect() {
    // Initialize theme based on stored preference
    this.applyTheme()

    // Listen for system theme changes
    this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.boundHandleSystemChange = this.handleSystemChange.bind(this)
    this.mediaQuery.addEventListener('change', this.boundHandleSystemChange)
  }

  disconnect() {
    if (this.mediaQuery) {
      this.mediaQuery.removeEventListener('change', this.boundHandleSystemChange)
    }
  }

  /**
   * Toggle between light and dark mode.
   * Cycles: light -> dark -> system -> light
   */
  toggle() {
    const current = this.getCurrentMode()
    let next

    if (current === 'light') {
      next = 'dark'
    } else if (current === 'dark') {
      next = 'system'
    } else {
      next = 'light'
    }

    this.setMode(next)
  }

  /**
   * Set a specific color mode
   */
  setMode(mode) {
    localStorage.setItem('colorMode', mode)
    this.colorModeValue = mode
    this.applyTheme()

    // Sync with server if we have a CSRF token (user is logged in)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      this.syncWithServer(mode, csrfToken)
    }
  }

  /**
   * Apply the current theme to the document
   */
  applyTheme() {
    const mode = this.getCurrentMode()
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

    if (mode === 'dark' || (mode === 'system' && prefersDark)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

  /**
   * Get the current color mode from localStorage or default
   */
  getCurrentMode() {
    return localStorage.getItem('colorMode') || this.colorModeValue || 'system'
  }

  /**
   * Handle system theme preference changes
   */
  handleSystemChange(e) {
    if (this.getCurrentMode() === 'system') {
      this.applyTheme()
    }
  }

  /**
   * Sync the color mode preference with the server
   */
  async syncWithServer(mode, csrfToken) {
    try {
      await fetch('/profile/update_color_mode', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ color_mode: mode })
      })
    } catch (error) {
      // Silently fail - the local preference is still saved
      console.warn('Failed to sync color mode with server:', error)
    }
  }
}
