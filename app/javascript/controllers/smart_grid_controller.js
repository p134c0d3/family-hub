import { Controller } from "@hotwired/stimulus"

// Smart grid controller for arranging images based on aspect ratios
// Creates optimal layouts like: portrait left + 2 landscapes stacked right
export default class extends Controller {
  static targets = ["container", "item", "image"]
  static values = { count: Number }

  connect() {
    this.loadedImages = 0
    this.aspectRatios = []
  }

  // Called when each image loads
  imageLoaded(event) {
    const img = event.target
    const index = parseInt(img.closest("[data-index]").dataset.index, 10)

    // Calculate aspect ratio (width / height)
    // > 1 = landscape, < 1 = portrait, ~1 = square
    const ratio = img.naturalWidth / img.naturalHeight
    this.aspectRatios[index] = {
      ratio,
      isPortrait: ratio < 0.9,
      isLandscape: ratio > 1.1,
      isSquare: ratio >= 0.9 && ratio <= 1.1
    }

    this.loadedImages++

    // Once all images have loaded, arrange the grid
    if (this.loadedImages === this.countValue) {
      this.arrangeGrid()
    }
  }

  arrangeGrid() {
    const count = this.countValue
    const container = this.containerTarget
    const items = this.itemTargets

    // Reset any previous custom styles
    items.forEach(item => {
      item.style.gridColumn = ""
      item.style.gridRow = ""
      item.style.height = ""
    })
    container.style.gridTemplateColumns = ""
    container.style.gridTemplateRows = ""

    // Single image - no grid needed
    if (count === 1) {
      items[0].style.maxHeight = "300px"
      this.imageTargets[0].style.maxHeight = "300px"
      return
    }

    // Two images - side by side, equal height
    if (count === 2) {
      container.classList.add("grid-cols-2")
      items.forEach(item => {
        item.style.height = "200px"
      })
      return
    }

    // Three images - smart layout based on aspect ratios
    if (count === 3) {
      this.arrangeThreeImages(container, items)
      return
    }

    // Four or more - 2-column grid with consistent sizing
    if (count >= 4) {
      this.arrangeFourPlusImages(container, items)
      return
    }
  }

  arrangeThreeImages(container, items) {
    const portraits = this.aspectRatios.filter(r => r && r.isPortrait)
    const landscapes = this.aspectRatios.filter(r => r && r.isLandscape)

    // Find the index of the portrait image if there is one
    const portraitIndex = this.aspectRatios.findIndex(r => r && r.isPortrait)

    // Optimal layout: 1 portrait + 2 non-portraits
    // Portrait takes left column full height, other two stack on right
    if (portraits.length === 1 && (landscapes.length >= 1 || portraits.length + landscapes.length < 3)) {
      // Use CSS Grid with 2 columns, portrait spans both rows
      container.style.gridTemplateColumns = "1fr 1fr"
      container.style.gridTemplateRows = "1fr 1fr"
      container.classList.remove("grid-cols-2")

      // Reorder items so portrait is first
      const sortedItems = this.sortItemsPortraitFirst(items, portraitIndex)

      // Portrait image spans full left column
      sortedItems[0].style.gridColumn = "1"
      sortedItems[0].style.gridRow = "1 / 3"
      sortedItems[0].style.height = "300px"

      // Other two images stack on right
      sortedItems[1].style.gridColumn = "2"
      sortedItems[1].style.gridRow = "1"
      sortedItems[1].style.height = "148px" // Account for gap

      sortedItems[2].style.gridColumn = "2"
      sortedItems[2].style.gridRow = "2"
      sortedItems[2].style.height = "148px"

      // Reorder DOM elements
      this.reorderDomElements(container, sortedItems)
      return
    }

    // Default: 2 on top, 1 on bottom (or 1 on top, 2 on bottom)
    container.classList.remove("grid-cols-2")
    container.style.gridTemplateColumns = "1fr 1fr"
    container.style.gridTemplateRows = "1fr 1fr"

    // First two side by side on top
    items[0].style.gridColumn = "1"
    items[0].style.gridRow = "1"
    items[0].style.height = "150px"

    items[1].style.gridColumn = "2"
    items[1].style.gridRow = "1"
    items[1].style.height = "150px"

    // Third spans full width on bottom
    items[2].style.gridColumn = "1 / 3"
    items[2].style.gridRow = "2"
    items[2].style.height = "150px"
  }

  arrangeFourPlusImages(container, items) {
    container.classList.remove("grid-cols-2")
    container.style.gridTemplateColumns = "1fr 1fr"

    // All items get consistent sizing
    items.forEach(item => {
      item.style.height = "150px"
    })
  }

  sortItemsPortraitFirst(items, portraitIndex) {
    const result = [...items]
    if (portraitIndex > 0) {
      // Move portrait to front
      const portrait = result.splice(portraitIndex, 1)[0]
      result.unshift(portrait)
    }
    return result
  }

  reorderDomElements(container, sortedItems) {
    // Create a document fragment to hold the sorted elements
    const fragment = document.createDocumentFragment()
    sortedItems.forEach(item => {
      fragment.appendChild(item)
    })
    // Clear container and append sorted items
    container.appendChild(fragment)
  }
}
