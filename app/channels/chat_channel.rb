# frozen_string_literal: true

# ChatChannel handles real-time messaging for chat conversations
#
# Subscriptions are scoped to individual chats. Users must be
# members of a chat (or the chat must be public) to subscribe.
#
# Broadcasts:
#   - new_message: When a message is created
#   - message_updated: When a message is edited
#   - message_deleted: When a message is soft-deleted
#   - reaction_added: When a reaction is added
#   - reaction_removed: When a reaction is removed
#   - typing: When a user starts/stops typing
#   - user_joined: When a user joins the chat
#   - user_left: When a user leaves the chat
#
class ChatChannel < ApplicationCable::Channel
  # Subscribe to a specific chat
  def subscribed
    @chat = Chat.find(params[:chat_id])

    # Verify access
    unless can_access_chat?
      reject
      return
    end

    stream_for @chat
  end

  def unsubscribed
    # Cleanup when user disconnects
    stop_all_streams
  end

  # Handle typing indicator broadcasts
  def typing(data)
    return unless @chat && can_access_chat?

    ChatChannel.broadcast_to(@chat, {
      type: 'typing',
      user_id: current_user.id,
      user_name: current_user.full_name,
      is_typing: data['is_typing']
    })
  end

  # Mark messages as read
  def mark_read
    return unless @chat && can_access_chat?

    @chat.mark_as_read!(current_user)
  end

  # Class methods for broadcasting from controllers/models

  # Broadcast a new message to the chat
  def self.broadcast_new_message(chat, message)
    broadcast_to(chat, {
      type: 'new_message',
      message_id: message.id,
      user_id: message.user_id,
      html: render_message(message)
    })
  end

  # Broadcast a message update
  def self.broadcast_message_updated(chat, message)
    broadcast_to(chat, {
      type: 'message_updated',
      message_id: message.id,
      html: render_message(message)
    })
  end

  # Broadcast a message deletion
  def self.broadcast_message_deleted(chat, message)
    broadcast_to(chat, {
      type: 'message_deleted',
      message_id: message.id,
      html: render_message(message)
    })
  end

  # Broadcast a reaction change
  def self.broadcast_reaction_change(chat, message, action)
    broadcast_to(chat, {
      type: "reaction_#{action}",
      message_id: message.id,
      reactions_html: render_reactions(message)
    })
  end

  # Broadcast message preview update for sidebar chat list
  # Called when a new message is created to update the last message preview
  def self.broadcast_message_preview(chat, message)
    preview_content = message.display_content.truncate(40)
    preview_content = '📎 Attachment' if preview_content.blank? && message.has_attachments?

    broadcast_to(chat, {
      type: 'message_preview',
      chat_id: chat.id,
      sender_id: message.user_id,
      sender_name: message.user.first_name,
      preview: preview_content,
      timestamp: message.created_at.iso8601
    })
  end

  private

  def can_access_chat?
    @chat.member?(current_user) || @chat.public?
  end

  # Render message partial for broadcasting
  def self.render_message(message)
    ApplicationController.render(
      partial: 'messages/message',
      locals: { message: message, current_user: message.user }
    )
  end

  # Render reactions partial for broadcasting
  def self.render_reactions(message)
    ApplicationController.render(
      partial: 'messages/reactions',
      locals: { message: message }
    )
  end
end
