# frozen_string_literal: true

# AccessRequest model for Family Hub
#
# Represents a request from a potential user to join the family hub.
# Admins review these requests and either approve (creating a user
# with a temporary password) or deny them.
#
# Statuses:
#   - pending: Awaiting admin review
#   - approved: Request approved, user created
#   - denied: Request denied
#
class AccessRequest < ApplicationRecord
  # Associations
  belongs_to :reviewed_by, class_name: 'User', optional: true

  # Validations
  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :date_of_birth, presence: true
  validates :city, presence: true, length: { minimum: 1, maximum: 100 }
  validates :status, inclusion: { in: %w[pending approved denied] }

  # Custom validation for unique pending email
  validate :unique_pending_email, on: :create
  validate :email_not_already_registered, on: :create

  # Callbacks
  before_validation :normalize_email

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :denied, -> { where(status: 'denied') }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods

  # Returns the requester's full name
  def full_name
    "#{first_name} #{last_name}"
  end

  # Check if request is pending
  def pending?
    status == 'pending'
  end

  # Check if request is approved
  def approved?
    status == 'approved'
  end

  # Check if request is denied
  def denied?
    status == 'denied'
  end

  # Approve the request and create a user
  # Returns the created user with temporary password, or nil if failed
  def approve!(admin, temporary_password)
    return nil unless pending?

    transaction do
      # Create the user
      user = User.create!(
        email: email,
        password: temporary_password,
        password_confirmation: temporary_password,
        first_name: first_name,
        last_name: last_name,
        date_of_birth: date_of_birth,
        city: city,
        password_changed: false
      )

      # Update the access request
      update!(
        status: 'approved',
        reviewed_by: admin,
        reviewed_at: Time.current
      )

      user
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    nil
  end

  # Deny the request
  def deny!(admin)
    return false unless pending?

    update(
      status: 'denied',
      reviewed_by: admin,
      reviewed_at: Time.current
    )
  end

  private

  # Normalize email to lowercase
  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end

  # Ensure no other pending request exists for this email
  def unique_pending_email
    if AccessRequest.pending.where(email: email).exists?
      errors.add(:email, "already has a pending access request")
    end
  end

  # Ensure email isn't already registered as a user
  def email_not_already_registered
    if User.exists?(email: email)
      errors.add(:email, "is already registered")
    end
  end
end
