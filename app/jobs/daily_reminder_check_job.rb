class DailyReminderCheckJob < ApplicationJob
  queue_as :default

  def perform
    EventReminder.pending.find_each do |reminder|
      EventReminderJob.perform_now(reminder.id)
    end
  end
end
