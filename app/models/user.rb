# frozen_string_literal: true

# User model for Family Hub
#
# Represents a family member with authentication, profile information,
# and preferences. The first user to be created automatically becomes
# an admin.
#
# Roles:
#   - admin: Can manage users, themes, and has full access
#   - member: Regular family member with standard access
#
# Statuses:
#   - active: Can log in and use the application
#   - inactive: Temporarily disabled, cannot log in
#   - removed: Soft-deleted, cannot log in
#
class User < ApplicationRecord
  # Secure password using bcrypt
  has_secure_password

  # Active Storage attachment for profile picture
  has_one_attached :avatar

  # Theme preference
  belongs_to :selected_theme, class_name: 'Theme', optional: true

  # Chat associations
  has_many :chat_memberships, dependent: :destroy
  has_many :chats, through: :chat_memberships
  has_many :messages, dependent: :destroy
  has_many :message_reactions, dependent: :destroy
  has_many :message_read_receipts, dependent: :destroy
  has_many :created_chats, class_name: 'Chat', foreign_key: :created_by_id, dependent: :nullify

  # Future associations (defined when models are created)
  # has_many :events, foreign_key: :created_by_id, dependent: :nullify
  # has_many :event_rsvps, dependent: :destroy
  # has_many :media_items, foreign_key: :uploaded_by_id, dependent: :nullify
  # has_many :mentions, dependent: :destroy

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :date_of_birth, presence: true
  validates :city, presence: true, length: { minimum: 1, maximum: 100 }

  validates :role, inclusion: { in: %w[admin member], message: "%{value} is not a valid role" }
  validates :status, inclusion: { in: %w[active inactive removed], message: "%{value} is not a valid status" }
  validates :color_mode, inclusion: { in: %w[light dark system], message: "%{value} is not a valid color mode" }

  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Callbacks
  before_validation :normalize_email
  before_create :set_first_user_as_admin
  before_create :generate_encryption_key_salt

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
  scope :searchable, -> { active.where.not(status: 'removed') }

  # Instance methods

  # Returns the user's full name
  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns initials for avatar placeholder
  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  # Check if user is an admin
  def admin?
    role == 'admin'
  end

  # Check if user is a regular member
  def member?
    role == 'member'
  end

  # Check if user account is active
  def active?
    status == 'active'
  end

  # Check if user account is inactive
  def inactive?
    status == 'inactive'
  end

  # Check if user account is removed
  def removed?
    status == 'removed'
  end

  # Check if user has changed their password (from temp password)
  def password_changed?
    self[:password_changed]
  end

  # Mark password as changed
  def mark_password_changed!
    update(password_changed: true)
  end

  # Activate the user
  def activate!
    update(status: 'active')
  end

  # Deactivate the user
  def deactivate!
    update(status: 'inactive')
  end

  # Soft remove the user
  def remove!
    update(status: 'removed')
  end

  # Make user an admin
  def make_admin!
    update(role: 'admin')
  end

  # Demote admin to member
  def make_member!
    update(role: 'member')
  end

  # Generate a temporary password
  def self.generate_temporary_password
    SecureRandom.alphanumeric(12)
  end

  # Find user by email (case-insensitive)
  def self.find_by_email(email)
    find_by('LOWER(email) = ?', email.to_s.downcase.strip)
  end

  # Authenticate user by email and password
  def self.authenticate(email, password)
    user = find_by_email(email)
    return nil unless user&.active?

    user.authenticate(password) || nil
  end

  private

  # Normalize email to lowercase
  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end

  # Make the first user an admin
  def set_first_user_as_admin
    self.role = 'admin' if User.count.zero?
  end

  # Generate a unique salt for user-specific encryption
  def generate_encryption_key_salt
    self.encryption_key_salt ||= SecureRandom.hex(32)
  end
end
