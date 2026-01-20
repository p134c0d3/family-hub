# frozen_string_literal: true

# Message model for Family Hub
#
# Represents a message in a chat conversation.
# Content is encrypted using Active Record Encryption.
#
class Message < ApplicationRecord
  include ActionView::RecordIdentifier

  # Constants
  MAX_ATTACHMENT_SIZE = 100.megabytes
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp image/heic image/heif].freeze
  ALLOWED_VIDEO_TYPES = %w[video/mp4 video/quicktime video/webm video/x-msvideo].freeze
  ALLOWED_DOCUMENT_TYPES = %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document text/plain].freeze
  ALLOWED_CONTENT_TYPES = (ALLOWED_IMAGE_TYPES + ALLOWED_VIDEO_TYPES + ALLOWED_DOCUMENT_TYPES).freeze

  # Encryption for message content
  encrypts :encrypted_content

  # Associations
  belongs_to :chat
  belongs_to :user
  belongs_to :parent_message, class_name: 'Message', optional: true
  has_many :replies, class_name: 'Message', foreign_key: :parent_message_id, dependent: :nullify
  has_many :reactions, class_name: 'MessageReaction', dependent: :destroy
  has_many :read_receipts, class_name: 'MessageReadReceipt', dependent: :destroy
  has_many_attached :attachments

  # Validations
  validates :encrypted_content, presence: true, unless: :has_attachments?
  validates :encrypted_content, length: { maximum: 10_000 }
  validate :validate_attachments

  # Callbacks
  after_create_commit :broadcast_message_created
  after_update_commit :broadcast_message_updated

  # Scopes
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :root_messages, -> { where(parent_message_id: nil) }
  scope :with_user, -> { includes(:user) }

  # Instance methods

  # Alias for convenience
  def content
    encrypted_content
  end

  def content=(value)
    self.encrypted_content = value
  end

  # Check if message is deleted (soft delete)
  def deleted?
    deleted_at.present?
  end

  # Soft delete the message
  def soft_delete!
    update(deleted_at: Time.current)
  end

  # Check if this is a reply to another message
  def reply?
    parent_message_id.present?
  end

  # Check if this message has replies (is a thread starter)
  def has_replies?
    replies.exists?
  end

  # Get thread reply count
  def reply_count
    replies.not_deleted.count
  end

  # Check if message has been edited
  def edited?
    edited
  end

  # Edit the message content
  def edit!(new_content)
    update(encrypted_content: new_content, edited: true)
  end

  # Check if message has attachments
  def has_attachments?
    attachments.attached?
  end

  # Add a reaction from a user
  def add_reaction(user, emoji)
    reactions.find_or_create_by(user: user, emoji: emoji)
  end

  # Remove a reaction from a user
  def remove_reaction(user, emoji)
    reactions.find_by(user: user, emoji: emoji)&.destroy
  end

  # Get grouped reactions with counts
  def grouped_reactions
    reactions.group(:emoji).count
  end

  # Check if user has reacted with a specific emoji
  def reacted_by?(user, emoji)
    reactions.exists?(user: user, emoji: emoji)
  end

  # Mark as read by user
  def mark_read_by!(user)
    read_receipts.find_or_create_by(user: user)
  end

  # Check if read by user
  def read_by?(user)
    read_receipts.exists?(user: user)
  end

  # Get list of users who have read the message
  def readers
    User.where(id: read_receipts.pluck(:user_id))
  end

  # Display content (handles deleted messages)
  def display_content
    deleted? ? '[Message deleted]' : content
  end

  # Check if attachment is an image
  def self.image?(attachment)
    ALLOWED_IMAGE_TYPES.include?(attachment.content_type)
  end

  # Check if attachment is a video
  def self.video?(attachment)
    ALLOWED_VIDEO_TYPES.include?(attachment.content_type)
  end

  # Check if attachment is a document
  def self.document?(attachment)
    ALLOWED_DOCUMENT_TYPES.include?(attachment.content_type)
  end

  # Get human-readable file size
  def self.human_file_size(bytes)
    return '0 B' if bytes.zero?

    units = %w[B KB MB GB]
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = units.length - 1 if exp > units.length - 1
    "#{(bytes.to_f / 1024**exp).round(1)} #{units[exp]}"
  end

  private

  # Validate attachment size and content type
  def validate_attachments
    return unless attachments.attached?

    attachments.each do |attachment|
      if attachment.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, "#{attachment.filename} is too large (max #{MAX_ATTACHMENT_SIZE / 1.megabyte}MB)")
      end

      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "#{attachment.filename} has an unsupported file type")
      end
    end
  end

  # Broadcast new message to chat via Turbo Streams
  # Uses per-user channels so each user sees correct message alignment
  def broadcast_message_created
    chat.members.find_each do |member|
      broadcast_append_to(
        [chat, member],
        target: 'messages',
        partial: 'messages/message',
        locals: { message: self, current_user: member }
      )
    end

    # Also broadcast the message preview for the sidebar chat list
    ChatChannel.broadcast_message_preview(chat, self)
  end

  # Broadcast message update to chat via Turbo Streams
  # Uses per-user channels so each user sees correct message alignment
  def broadcast_message_updated
    chat.members.find_each do |member|
      broadcast_replace_to(
        [chat, member],
        target: dom_id(self),
        partial: 'messages/message',
        locals: { message: self, current_user: member }
      )
    end
  end
end
