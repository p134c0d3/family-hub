import { Controller } from "@hotwired/stimulus"

// Lightbox controller for viewing images in a chat
// Allows navigation through ALL images in the conversation
export default class extends Controller {
  static targets = ["overlay", "image", "counter", "caption"]

  connect() {
    this.currentIndex = 0
    this.images = []
    this.boundKeyHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
    this.unlockScroll()
  }

  // Open lightbox with a specific image
  open(event) {
    event.preventDefault()

    const clickedUrl = event.currentTarget.dataset.lightboxUrl

    // Collect all images in the chat
    this.collectImages()

    // Find the index of the clicked image
    this.currentIndex = this.images.findIndex(img => img.url === clickedUrl)
    if (this.currentIndex === -1) this.currentIndex = 0

    // Show the overlay
    this.showOverlay()
    this.displayImage()

    // Add keyboard listener
    document.addEventListener("keydown", this.boundKeyHandler)
  }

  // Collect all images from the chat messages
  collectImages() {
    this.images = []

    // Find all lightbox-enabled images in the messages container
    const messagesContainer = document.getElementById("messages")
    if (!messagesContainer) return

    const imageElements = messagesContainer.querySelectorAll("[data-lightbox-url]")

    imageElements.forEach(el => {
      this.images.push({
        url: el.dataset.lightboxUrl,
        caption: el.dataset.lightboxCaption || "",
        sender: el.dataset.lightboxSender || ""
      })
    })
  }

  // Show the overlay with animation
  showOverlay() {
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")

    // Trigger animation
    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.overlayTarget.classList.add("opacity-100")
      this.imageTarget.classList.remove("scale-95")
      this.imageTarget.classList.add("scale-100")
    })

    this.lockScroll()
  }

  // Hide the overlay with animation
  close(event) {
    // Only close if clicking the backdrop (not the image)
    if (event && event.target !== this.overlayTarget && !event.target.closest("[data-action*='lightbox#close']")) {
      return
    }

    this.overlayTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("opacity-0")
    this.imageTarget.classList.remove("scale-100")
    this.imageTarget.classList.add("scale-95")

    setTimeout(() => {
      this.overlayTarget.classList.remove("flex")
      this.overlayTarget.classList.add("hidden")
    }, 300)

    document.removeEventListener("keydown", this.boundKeyHandler)
    this.unlockScroll()
  }

  // Navigate to previous image (more recent)
  previous(event) {
    if (event) event.stopPropagation()
    if (this.images.length <= 1) return

    this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length
    this.displayImage()
  }

  // Navigate to next image (older)
  next(event) {
    if (event) event.stopPropagation()
    if (this.images.length <= 1) return

    this.currentIndex = (this.currentIndex + 1) % this.images.length
    this.displayImage()
  }

  // Display the current image
  displayImage() {
    const image = this.images[this.currentIndex]
    if (!image) return

    // Add loading state
    this.imageTarget.classList.add("opacity-50")

    // Create new image to preload
    const img = new Image()
    img.onload = () => {
      this.imageTarget.src = image.url
      this.imageTarget.classList.remove("opacity-50")
    }
    img.src = image.url

    // Update counter
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} of ${this.images.length}`
    }

    // Update caption
    if (this.hasCaptionTarget && image.sender) {
      this.captionTarget.textContent = `Sent by ${image.sender}`
    }
  }

  // Handle keyboard navigation
  handleKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break
      case "ArrowLeft":
        this.previous()
        break
      case "ArrowRight":
        this.next()
        break
    }
  }

  // Prevent body scroll when lightbox is open
  lockScroll() {
    document.body.style.overflow = "hidden"
  }

  unlockScroll() {
    document.body.style.overflow = ""
  }
}
