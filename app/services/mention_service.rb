# frozen_string_literal: true

# MentionService handles parsing @mentions from message content
# and creating notifications for mentioned users.
#
# Usage:
#   MentionService.process(message)  # Parse and create notifications
#   MentionService.render_with_highlights(content, mentioned_user_ids)  # For display
#
class MentionService
  # Pattern matches @FirstName or @FirstName LastName (capitalized names)
  # Examples: @John, @John Smith, @Mary Jane
  MENTION_PATTERN = /@([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/

  class << self
    # Process a message for @mentions
    # - Extracts mentioned names from content
    # - Matches them to chat members
    # - Stores mentioned user IDs on the message
    # - Creates notifications for mentioned users
    def process(message)
      return if message.content.blank?

      mentioned_names = extract_mention_names(message.content)
      return if mentioned_names.empty?

      # Find matching users who are members of this chat
      mentioned_users = find_mentioned_users(mentioned_names, message.chat)
      return if mentioned_users.empty?

      # Store mentioned user IDs on the message
      message.update_column(:mentioned_user_ids, mentioned_users.map(&:id))

      # Create notifications for each mentioned user
      create_mention_notifications(message, mentioned_users)
    end

    # Render message content with @mentions highlighted
    # Returns HTML-safe string with mentions wrapped in styled spans
    def render_with_highlights(content, mentioned_user_ids = [])
      return content if content.blank?

      # If no mentions, return plain content
      return ERB::Util.html_escape(content) if mentioned_user_ids.blank?

      # Get the mentioned users to know their names
      users = User.where(id: mentioned_user_ids).index_by(&:first_name)

      # Escape HTML first, then replace mentions with highlighted spans
      escaped_content = ERB::Util.html_escape(content)

      # Replace each @Name with a highlighted span
      escaped_content.gsub(MENTION_PATTERN) do |match|
        name = Regexp.last_match(1).split.first # Get first name only
        if users[name]
          "<span class=\"mention\">#{match}</span>"
        else
          match
        end
      end.html_safe
    end

    private

    # Extract all @Name mentions from content
    def extract_mention_names(content)
      content.scan(MENTION_PATTERN).flatten.map { |name| name.split.first }
    end

    # Find users matching the mentioned names who are members of the chat
    def find_mentioned_users(names, chat)
      return [] if names.empty?

      # Get chat members whose first name matches any mentioned name
      chat.members.where(first_name: names).to_a
    end

    # Create notification for each mentioned user
    def create_mention_notifications(message, mentioned_users)
      mentioned_users.each do |mentioned_user|
        # Don't notify the message author if they mention themselves
        next if mentioned_user.id == message.user_id

        # Check if user should receive notifications
        next unless mentioned_user.should_receive_notification?(message.chat)

        # Don't create duplicate notifications
        next if Notification.exists?(
          user: mentioned_user,
          actor: message.user,
          notifiable: message,
          notification_type: 'mention'
        )

        Notification.create!(
          user: mentioned_user,
          actor: message.user,
          notifiable: message,
          notification_type: 'mention'
        )
      end
    end
  end
end
