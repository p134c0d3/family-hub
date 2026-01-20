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
  has_many :users, foreign_key: :selected_theme_id, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :colors, presence: true
  validate :validate_colors_structure

  # Callbacks
  before_save :ensure_single_default, if: :is_default?

  # Scopes
  scope :default_theme, -> { find_by(is_default: true) }
  scope :ordered, -> { order(:name) }

  # Color keys required in the colors JSON
  REQUIRED_COLOR_KEYS = %w[
    primary
    secondary
    accent
    background_light
    background_dark
    surface_light
    surface_dark
    text_light
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
  def to_css_variables(mode = :light)
    return '' if colors.blank?

    suffix = mode == :dark ? '_dark' : '_light'

    vars = []
    vars << "--theme-primary: #{color('primary')};"
    vars << "--theme-secondary: #{color('secondary')};"
    vars << "--theme-accent: #{color('accent')};"
    vars << "--theme-background: #{color("background#{suffix}")};"
    vars << "--theme-surface: #{color("surface#{suffix}")};"
    vars << "--theme-text: #{color("text#{suffix}")};"

    vars.join("\n")
  end

  # Class methods

  # Get the default theme or create one if none exists
  def self.default
    default_theme || create_default_theme
  end

  # Create the default "Ocean Blue" theme
  def self.create_default_theme
    create!(
      name: 'Ocean Blue',
      is_default: true,
      colors: {
        'primary' => '#3B82F6',
        'secondary' => '#64748B',
        'accent' => '#0EA5E9',
        'background_light' => '#FFFFFF',
        'background_dark' => '#0F172A',
        'surface_light' => '#F8FAFC',
        'surface_dark' => '#1E293B',
        'text_light' => '#1E293B',
        'text_dark' => '#F8FAFC'
      }
    )
  end

  private

  # Validate that colors contains all required keys with valid hex values
  def validate_colors_structure
    return if colors.blank?

    unless colors.is_a?(Hash)
      errors.add(:colors, 'must be a hash')
      return
    end

    missing_keys = REQUIRED_COLOR_KEYS - colors.keys
    if missing_keys.any?
      errors.add(:colors, "missing required keys: #{missing_keys.join(', ')}")
    end

    # Validate hex color format
    colors.each do |key, value|
      unless value.to_s.match?(/\A#[0-9A-Fa-f]{6}\z/)
        errors.add(:colors, "#{key} must be a valid hex color (e.g., #3B82F6)")
      end
    end
  end

  # Ensure only one theme is marked as default
  def ensure_single_default
    Theme.where.not(id: id).update_all(is_default: false)
  end
end
