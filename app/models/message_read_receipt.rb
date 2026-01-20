# frozen_string_literal: true

# MessageReadReceipt model for Family Hub
#
# Tracks when a user has read a specific message. Used for showing
# read receipts (e.g., "Seen by Alice, Bob") in chat conversations.
#
class MessageReadReceipt < ApplicationRecord
  # Associations
  belongs_to :message
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :message_id, message: "has already marked this message as read" }

  # Scopes
  scope :for_message, ->(message) { where(message: message) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create_commit :broadcast_read_receipt

  # Instance methods

  # Get the time when the message was read
  def read_at
    created_at
  end

  private

  # Broadcast when a message is read
  def broadcast_read_receipt
    # Will be implemented with ActionCable
    # ChatChannel.broadcast_to(message.chat, { type: 'message_read', receipt: self })
  end
end
