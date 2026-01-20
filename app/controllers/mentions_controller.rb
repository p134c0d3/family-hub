# frozen_string_literal: true

# MentionsController handles the autocomplete API for @mentions
#
# Endpoints:
#   GET /chats/:chat_id/mentions?query=Jo - Returns matching chat members
#
class MentionsController < ApplicationController
  before_action :require_authentication
  before_action :set_chat
  before_action :authorize_chat_access

  # GET /chats/:chat_id/mentions
  # Returns chat members matching the query for autocomplete
  def index
    query = params[:query].to_s.strip

    @members = if query.present?
      # Search by first name (case-insensitive)
      @chat.members
           .where("LOWER(first_name) LIKE ?", "#{query.downcase}%")
           .where.not(id: current_user.id)  # Don't suggest mentioning yourself
           .limit(5)
    else
      # Return all members (except current user) when no query
      @chat.members
           .where.not(id: current_user.id)
           .limit(5)
    end

    render json: @members.map { |member| member_json(member) }
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def authorize_chat_access
    unless @chat.member?(current_user) || @chat.public?
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def member_json(member)
    {
      id: member.id,
      first_name: member.first_name,
      full_name: member.full_name,
      avatar_url: member.avatar.attached? ? url_for(member.avatar) : nil,
      initials: member.initials
    }
  end
end
