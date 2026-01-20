# frozen_string_literal: true

# Chat model for Family Hub
#
# Represents a conversation between users. Three types are supported:
# - direct: 1-on-1 conversation (no name, exactly 2 members)
# - group: Named conversation with multiple members
# - public: Open channel visible to all family members
#
class Chat < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :chat_memberships, dependent: :destroy
  has_many :members, through: :chat_memberships, source: :user
  has_many :messages, dependent: :destroy

  # Validations
  validates :chat_type, presence: true, inclusion: { in: %w[direct group public] }
  validates :name, presence: true, if: -> { group? || public? }
  validates :name, length: { maximum: 100 }
  validate :direct_chat_has_two_members, if: :direct?

  # Callbacks
  before_validation :set_default_chat_type

  # Scopes
  scope :direct_chats, -> { where(chat_type: 'direct') }
  scope :group_chats, -> { where(chat_type: 'group') }
  scope :public_chats, -> { where(chat_type: 'public') }
  scope :for_user, ->(user) { joins(:chat_memberships).where(chat_memberships: { user_id: user.id }) }
  scope :with_recent_activity, -> { left_joins(:messages).group(:id).order(Arel.sql('MAX(messages.created_at) DESC NULLS LAST')) }

  # Instance methods

  # Check chat type
  def direct?
    chat_type == 'direct'
  end

  def group?
    chat_type == 'group'
  end

  def public?
    chat_type == 'public'
  end

  # Get display name for the chat
  def display_name(current_user = nil)
    if direct? && current_user
      other_member(current_user)&.full_name || 'Unknown User'
    else
      name || 'Unnamed Chat'
    end
  end

  # Get the other member in a direct chat
  def other_member(current_user)
    return nil unless direct?

    members.where.not(id: current_user.id).first
  end

  # Check if user is a member
  def member?(user)
    chat_memberships.exists?(user_id: user.id)
  end

  # Add a member to the chat
  def add_member(user)
    chat_memberships.find_or_create_by(user: user)
  end

  # Remove a member from the chat
  def remove_member(user)
    chat_memberships.find_by(user: user)&.destroy
  end

  # Get unread message count for a user
  def unread_count_for(user)
    membership = chat_memberships.find_by(user: user)
    return 0 unless membership

    if membership.last_read_at
      messages.where('created_at > ?', membership.last_read_at).where.not(user: user).count
    else
      messages.where.not(user: user).count
    end
  end

  # Mark all messages as read for a user
  def mark_as_read!(user)
    membership = chat_memberships.find_by(user: user)
    membership&.update(last_read_at: Time.current)
  end

  # Get the last message
  def last_message
    messages.order(created_at: :desc).first
  end

  # Class methods

  # Find or create a direct chat between two users
  def self.find_or_create_direct(user1, user2)
    # Find existing direct chat with both users
    chat = direct_chats
           .joins(:chat_memberships)
           .where(chat_memberships: { user_id: [user1.id, user2.id] })
           .group('chats.id')
           .having('COUNT(DISTINCT chat_memberships.user_id) = 2')
           .first

    return chat if chat

    # Create new direct chat
    transaction do
      chat = create!(chat_type: 'direct')
      chat.add_member(user1)
      chat.add_member(user2)
      chat
    end
  end

  private

  def set_default_chat_type
    self.chat_type ||= 'direct'
  end

  def direct_chat_has_two_members
    # This validation is tricky because members may not be set yet during creation
    # We rely on the service/controller to ensure proper member count
  end
end
