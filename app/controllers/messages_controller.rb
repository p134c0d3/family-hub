# frozen_string_literal: true

# MessagesController handles message operations within a chat
#
# Messages support:
#   - Text content (encrypted with Active Record Encryption)
#   - File attachments via Active Storage
#   - Threaded replies via parent_message_id
#   - Soft deletion
#   - Editing (with edit history tracking)
#
class MessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_chat
  before_action :authorize_chat_access
  before_action :set_message, only: [:update, :destroy]
  before_action :authorize_message_owner, only: [:update, :destroy]

  # POST /chats/:chat_id/messages
  def create
    @message = @chat.messages.build(message_params)
    @message.user = current_user

    if @message.save
      # Mark chat as read for the sender
      @chat.mark_as_read!(current_user)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "chats/message_form",
            locals: { chat: @chat, message: @message }
          )
        end
        format.html { redirect_to @chat, alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  # PATCH /chats/:chat_id/messages/:id
  def update
    if @message.edit!(message_params[:content])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@message),
            partial: "messages/message",
            locals: { message: @message, current_user: current_user }
          )
        end
        format.html { redirect_to @chat, alert: "Failed to update message" }
      end
    end
  end

  # DELETE /chats/:chat_id/messages/:id
  def destroy
    @message.soft_delete!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @chat, notice: "Message deleted" }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def set_message
    @message = @chat.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content, :parent_message_id, attachments: [])
  end

  def authorize_chat_access
    unless @chat.member?(current_user) || @chat.public?
      redirect_to chats_path, alert: "You don't have access to this chat"
    end
  end

  def authorize_message_owner
    unless @message.user == current_user || current_user.admin?
      redirect_to @chat, alert: "You can only modify your own messages"
    end
  end
end
