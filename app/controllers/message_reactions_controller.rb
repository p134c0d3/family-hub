# frozen_string_literal: true

# MessageReactionsController handles adding/removing emoji reactions to messages
#
# Reactions are toggled: clicking an emoji you've already added removes it,
# clicking a new emoji adds it.
#
class MessageReactionsController < ApplicationController
  before_action :require_authentication
  before_action :set_chat
  before_action :set_message
  before_action :authorize_chat_access

  # POST /chats/:chat_id/messages/:message_id/reactions
  def create
    emoji = params[:emoji]

    if emoji.blank?
      head :unprocessable_entity
      return
    end

    # Toggle reaction: if exists, remove it; otherwise, add it
    existing = @message.reactions.find_by(user: current_user, emoji: emoji)

    if existing
      existing.destroy
      @action = :removed
    else
      @message.add_reaction(current_user, emoji)
      @action = :added
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @chat }
    end
  end

  # DELETE /chats/:chat_id/messages/:message_id/reactions/:id
  def destroy
    @reaction = @message.reactions.find(params[:id])

    if @reaction.user == current_user || current_user.admin?
      @reaction.destroy
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("message_#{@message.id}_reactions", partial: 'messages/reactions_bar', locals: { message: @message, current_user: current_user }) }
      format.html { redirect_to @chat }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def set_message
    @message = @chat.messages.find(params[:message_id])
  end

  def authorize_chat_access
    unless @chat.member?(current_user) || @chat.public?
      redirect_to chats_path, alert: "You don't have access to this chat"
    end
  end
end
