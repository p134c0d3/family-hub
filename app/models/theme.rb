# frozen_string_literal: true

# Theme model for Family Hub
#
# Admin-created color themes that users can select.
# Each theme defines a set of colors that override CSS custom properties.
#
# Color structure:
# {
#   "primary": "#3B82F6",
#   "secondary": "#64748B",
#   "accent": "#0EA5E9",
#   "background_light": "#FFFFFF",
#   "background_dark": "#1E293B",
#   "surface_light": "#F8FAFC",
#   "surface_dark": "#334155",
#   "text_light": "#1E293B",
#   "text_dark": "#F8FAFC"
# }
#
class Theme < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :colors, presence: true
  validate :validate_colors_structure

  # Callbacks
  before_save :ensure_single_default, if: :is_default?

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :default_theme, -> { find_by(is_default: true) }
  scope :ordered, -> { order(:name) }

  # Full design system colors (15+ keys)
  REQUIRED_COLORS = %w[
    primary
    secondary
    accent
    background
    surface
    text
    success
    warning
    error
    info
    border
    shadow
    primary_dark
    secondary_dark
    accent_dark
    background_dark
    surface_dark
    text_dark
  ].freeze

  # Instance methods

  # Get a specific color value
  def color(key)
    colors&.dig(key.to_s)
  end

  # Set this theme as the default
  def make_default!
    Theme.where(is_default: true).update_all(is_default: false)
    update!(is_default: true)
  end

  # Generate CSS custom properties for this theme
  def to_css_variables(dark_mode: false)
    return '' if colors.blank?

    vars = []
    colors.each do |key, value|
      if dark_mode && colors["#{key}_dark"].present?
        vars << "--color-#{key.dasherize}: #{colors["#{key}_dark"]};"
      elsif !key.end_with?('_dark')
        vars << "--color-#{key.dasherize}: #{value};"
      end
    end
    vars.compact.join("\n")
  end

  # Class methods

  # Get the default theme or create one if none exists
  def self.default
    default_theme || create_default_theme
  end

  # Get default color palette
  def self.default_colors
    {
      'primary' => '#3b82f6',
      'secondary' => '#8b5cf6',
      'accent' => '#f59e0b',
      'background' => '#ffffff',
      'surface' => '#f8fafc',
      'text' => '#1f2937',
      'success' => '#10b981',
      'warning' => '#f59e0b',
      'error' => '#ef4444',
      'info' => '#3b82f6',
      'border' => '#e2e8f0',
      'shadow' => 'rgba(0,0,0,0.1)',
      'primary_dark' => '#60a5fa',
      'secondary_dark' => '#a78bfa',
      'accent_dark' => '#fbbf24',
      'background_dark' => '#111827',
      'surface_dark' => '#1f2937',
      'text_dark' => '#f9fafb'
    }
  end

  # Create the default "Ocean Blue" theme
  def self.create_default_theme
    create!(
      name: 'Ocean Blue',
      is_default: true,
      colors: default_colors
    )
  end

  private

  # Validate that colors contains all required keys
  def validate_colors_structure
    return if colors.blank?

    unless colors.is_a?(Hash)
      errors.add(:colors, 'must be a hash')
      return
    end

    # Only check non-dark variants
    missing_keys = REQUIRED_COLORS.reject { |k| k.end_with?('_dark') } - colors.keys
    if missing_keys.any?
      errors.add(:colors, "missing required keys: #{missing_keys.join(', ')}")
    end

    # Validate color formats (hex or rgba)
    colors.each do |key, value|
      next if value.to_s.start_with?('rgba(') || value.to_s.start_with?('rgb(')
      unless value.to_s.match?(/\A#[0-9A-Fa-f]{6}\z/)
        errors.add(:colors, "#{key} must be a valid hex color or rgb/rgba value")
      end
    end
  end

  # Ensure only one theme is marked as default
  def ensure_single_default
    return unless is_default_changed? && is_default?
    Theme.where.not(id: id).update_all(is_default: false)
  end
end
