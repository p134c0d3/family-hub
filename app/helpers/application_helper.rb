module ApplicationHelper
  # Render message content with @mentions highlighted
  # Returns HTML-safe string with mentions wrapped in styled spans
  def render_message_content(message)
    MentionService.render_with_highlights(message.content, message.mentioned_user_ids)
  end
end
