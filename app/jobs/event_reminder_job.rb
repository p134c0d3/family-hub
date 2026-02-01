class EventReminderJob < ApplicationJob
  queue_as :default

  def perform(reminder_id)
    reminder = EventReminder.find_by(id: reminder_id)
    return unless reminder && !reminder.sent?

    event = reminder.event
    user = reminder.user

    return if event.nil?

    Notification.create!(
      user: user,
      actor: event.created_by,
      notifiable: event,
      notification_type: 'event_reminder',
      data: {
        event_title: event.title,
        event_start: event.start_at.iso8601,
        minutes_before: reminder.minutes_before
      }
    )

    reminder.update!(sent: true)
  end
end
