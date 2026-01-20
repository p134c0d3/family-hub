# frozen_string_literal: true

module ApplicationCable
  # Connection class for ActionCable
  #
  # Handles authentication for WebSocket connections.
  # Users must be logged in to establish a connection.
  #
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if (user_id = cookies.encrypted[:user_id])
        User.find_by(id: user_id, status: 'active')
      else
        reject_unauthorized_connection
      end
    end
  end
end
