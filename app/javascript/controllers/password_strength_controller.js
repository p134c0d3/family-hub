import { Controller } from "@hotwired/stimulus"

/**
 * Password Strength Controller
 *
 * Uses zxcvbn library (lazy-loaded) to estimate password strength
 * and provide visual feedback with helpful suggestions.
 *
 * Usage:
 *   <div data-controller="password-strength">
 *     <input type="password" data-password-strength-target="input" data-action="input->password-strength#evaluate">
 *     <div data-password-strength-target="meter"></div>
 *     <div data-password-strength-target="feedback"></div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["input", "meter", "feedback"]

  // User inputs to avoid in password (email, name, etc.)
  static values = {
    userInputs: { type: Array, default: [] }
  }

  connect() {
    this.zxcvbn = null
    this.loadingZxcvbn = false

    // Build the meter UI
    if (this.hasMeterTarget) {
      this.buildMeterUI()
    }
  }

  buildMeterUI() {
    this.meterTarget.innerHTML = `
      <div class="mt-2">
        <div class="flex gap-1 mb-1">
          <div class="h-1 flex-1 rounded-full bg-theme-border transition-colors duration-200" data-bar="0"></div>
          <div class="h-1 flex-1 rounded-full bg-theme-border transition-colors duration-200" data-bar="1"></div>
          <div class="h-1 flex-1 rounded-full bg-theme-border transition-colors duration-200" data-bar="2"></div>
          <div class="h-1 flex-1 rounded-full bg-theme-border transition-colors duration-200" data-bar="3"></div>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-xs text-theme-secondary" data-strength-label></span>
          <span class="text-xs text-theme-secondary" data-crack-time></span>
        </div>
      </div>
    `

    this.bars = this.meterTarget.querySelectorAll('[data-bar]')
    this.strengthLabel = this.meterTarget.querySelector('[data-strength-label]')
    this.crackTime = this.meterTarget.querySelector('[data-crack-time]')
  }

  async evaluate() {
    const password = this.inputTarget.value

    // Hide meter if password is empty
    if (!password) {
      this.resetMeter()
      return
    }

    // Lazy load zxcvbn on first use
    if (!this.zxcvbn && !this.loadingZxcvbn) {
      this.loadingZxcvbn = true
      try {
        const module = await import("zxcvbn")
        this.zxcvbn = module.default || module
      } catch (error) {
        console.error("Failed to load zxcvbn:", error)
        return
      }
      this.loadingZxcvbn = false
    }

    // Wait if still loading
    if (!this.zxcvbn) return

    // Evaluate password strength
    const result = this.zxcvbn(password, this.userInputsValue)
    this.updateMeter(result)
    this.updateFeedback(result)
  }

  updateMeter(result) {
    if (!this.hasMeterTarget) return

    const { score } = result
    const colors = [
      'bg-red-500',      // 0 - Very weak
      'bg-orange-500',   // 1 - Weak
      'bg-yellow-500',   // 2 - Fair
      'bg-lime-500',     // 3 - Strong
      'bg-green-500'     // 4 - Very strong
    ]

    const labels = [
      'Very weak',
      'Weak',
      'Fair',
      'Strong',
      'Very strong'
    ]

    // Update bars
    this.bars.forEach((bar, index) => {
      // Remove all color classes
      bar.classList.remove('bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-lime-500', 'bg-green-500')

      if (index <= score) {
        bar.classList.add(colors[score])
      } else {
        bar.classList.add('bg-theme-border')
      }
    })

    // Update label
    if (this.strengthLabel) {
      this.strengthLabel.textContent = labels[score]
      this.strengthLabel.className = 'text-xs font-medium'

      // Color the label
      const labelColors = [
        'text-red-600 dark:text-red-400',
        'text-orange-600 dark:text-orange-400',
        'text-yellow-600 dark:text-yellow-400',
        'text-lime-600 dark:text-lime-400',
        'text-green-600 dark:text-green-400'
      ]
      this.strengthLabel.classList.add(...labelColors[score].split(' '))
    }

    // Update crack time
    if (this.crackTime) {
      this.crackTime.textContent = result.crack_times_display.offline_slow_hashing_1e4_per_second
    }
  }

  updateFeedback(result) {
    if (!this.hasFeedbackTarget) return

    const { feedback } = result
    const messages = []

    if (feedback.warning) {
      messages.push(feedback.warning)
    }

    if (feedback.suggestions && feedback.suggestions.length > 0) {
      messages.push(...feedback.suggestions)
    }

    if (messages.length > 0) {
      this.feedbackTarget.innerHTML = `
        <ul class="mt-2 text-xs text-theme-secondary space-y-1">
          ${messages.map(msg => `<li class="flex items-start gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mt-0.5 flex-shrink-0 text-theme-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>${msg}</span>
          </li>`).join('')}
        </ul>
      `
      this.feedbackTarget.classList.remove('hidden')
    } else {
      this.feedbackTarget.innerHTML = ''
      this.feedbackTarget.classList.add('hidden')
    }
  }

  resetMeter() {
    if (this.bars) {
      this.bars.forEach(bar => {
        bar.classList.remove('bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-lime-500', 'bg-green-500')
        bar.classList.add('bg-theme-border')
      })
    }

    if (this.strengthLabel) {
      this.strengthLabel.textContent = ''
    }

    if (this.crackTime) {
      this.crackTime.textContent = ''
    }

    if (this.hasFeedbackTarget) {
      this.feedbackTarget.innerHTML = ''
      this.feedbackTarget.classList.add('hidden')
    }
  }
}
