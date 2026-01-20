# frozen_string_literal: true

# ChatsController handles chat conversations
#
# Chat types:
#   - direct: One-on-one conversation between two users
#   - group: Multi-user conversation with a name
#   - public: Open chat room visible to all family members
#
class ChatsController < ApplicationController
  before_action :require_authentication
  before_action :set_chat, only: [:show, :edit, :update, :destroy, :add_member, :remove_member, :leave]
  before_action :authorize_chat_access, only: [:show, :edit, :update, :destroy, :add_member, :remove_member]

  # GET /chats
  def index
    @chats = current_user.chats
                         .includes(:members, :messages)
                         .with_recent_activity
    @users = User.active.where.not(id: current_user.id).order(:first_name)

    # For two-column layout: load active chat if specified via query param
    if params[:active_chat].present?
      @active_chat = Chat.find_by(id: params[:active_chat])
      if @active_chat && (@active_chat.member?(current_user) || @active_chat.public?)
        @messages = @active_chat.messages
                                .not_deleted
                                .includes(:user, :reactions, :replies)
                                .chronological
                                .limit(50)
        @active_chat.mark_as_read!(current_user)

        # Handle Turbo Frame requests - just return the conversation frame
        if turbo_frame_request?
          render partial: 'chats/conversation_frame', locals: {
            chat: @active_chat,
            messages: @messages,
            current_user: current_user
          } and return
        end
      else
        @active_chat = nil
        @messages = []
      end
    else
      @active_chat = nil
      @messages = []
    end
  end

  # GET /chats/:id
  def show
    @messages = @chat.messages
                     .not_deleted
                     .includes(:user, :reactions, :replies)
                     .chronological
                     .limit(50)
    @chat.mark_as_read!(current_user)

    # Handle Turbo Frame requests for the two-column layout
    # Renders just the conversation frame, not the full page
    if turbo_frame_request?
      render partial: 'chats/conversation_frame', locals: {
        chat: @chat,
        messages: @messages,
        current_user: current_user
      } and return
    end
    # Otherwise, renders show.html.erb (for mobile direct navigation)
  end

  # GET /chats/new
  def new
    @chat = Chat.new
    @users = User.active.where.not(id: current_user.id).order(:first_name)

    # Handle Turbo Frame requests for the two-column layout
    if turbo_frame_request?
      render partial: 'chats/new_chat_frame', locals: {
        users: @users,
        current_user: current_user
      } and return
    end
  end

  # POST /chats
  def create
    case params[:chat_type]
    when 'direct'
      create_direct_chat
    when 'group'
      create_group_chat
    else
      redirect_to chats_path, alert: "Invalid chat type"
    end
  end

  # GET /chats/:id/edit
  def edit
    unless @chat.group?
      redirect_to @chat, alert: "Only group chats can be edited"
    end
    @users = User.active.where.not(id: current_user.id).order(:first_name)
  end

  # PATCH /chats/:id
  def update
    unless @chat.group?
      redirect_to @chat, alert: "Only group chats can be edited"
      return
    end

    if @chat.update(chat_params)
      redirect_to @chat, notice: "Chat updated successfully"
    else
      @users = User.active.where.not(id: current_user.id).order(:first_name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /chats/:id
  def destroy
    unless @chat.created_by == current_user || current_user.admin?
      redirect_to chats_path, alert: "You don't have permission to delete this chat"
      return
    end

    @chat.destroy
    redirect_to chats_path, notice: "Chat deleted successfully"
  end

  # POST /chats/:id/add_member
  def add_member
    unless @chat.group?
      redirect_to @chat, alert: "Cannot add members to this chat type"
      return
    end

    user = User.find(params[:user_id])
    @chat.add_member(user)
    redirect_to @chat, notice: "#{user.full_name} added to the chat"
  rescue ActiveRecord::RecordNotFound
    redirect_to @chat, alert: "User not found"
  end

  # DELETE /chats/:id/remove_member
  def remove_member
    unless @chat.group?
      redirect_to @chat, alert: "Cannot remove members from this chat type"
      return
    end

    user = User.find(params[:user_id])

    if user == @chat.created_by && !current_user.admin?
      redirect_to @chat, alert: "Cannot remove the chat creator"
      return
    end

    @chat.remove_member(user)
    redirect_to @chat, notice: "#{user.full_name} removed from the chat"
  rescue ActiveRecord::RecordNotFound
    redirect_to @chat, alert: "User not found"
  end

  # POST /chats/:id/leave
  def leave
    if @chat.direct?
      redirect_to @chat, alert: "Cannot leave a direct message conversation"
      return
    end

    @chat.remove_member(current_user)
    redirect_to chats_path, notice: "You have left the chat"
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:name)
  end

  def authorize_chat_access
    unless @chat.member?(current_user) || @chat.public?
      redirect_to chats_path, alert: "You don't have access to this chat"
    end
  end

  def create_direct_chat
    other_user = User.find(params[:user_id])
    @chat = Chat.find_or_create_direct(current_user, other_user)
    # Redirect to index with this chat active (for two-column layout)
    redirect_to chats_path(active_chat: @chat.id)
  rescue ActiveRecord::RecordNotFound
    redirect_to chats_path, alert: "User not found"
  end

  def create_group_chat
    @chat = Chat.new(
      name: params.dig(:chat, :name),
      chat_type: 'group',
      created_by: current_user
    )

    if @chat.save
      @chat.add_member(current_user)

      # Add selected members
      member_ids = params[:member_ids] || []
      User.where(id: member_ids).find_each do |user|
        @chat.add_member(user)
      end

      # Redirect to index with this chat active (for two-column layout)
      redirect_to chats_path(active_chat: @chat.id), notice: "Group chat created successfully"
    else
      @users = User.active.where.not(id: current_user.id).order(:first_name)
      render :new, status: :unprocessable_entity
    end
  end
end
