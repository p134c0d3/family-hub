# frozen_string_literal: true

# EventReminder model for Family Hub
#
# Represents a reminder for a user about an upcoming event.
# Reminders are scheduled to trigger at a specific time before the event.
#
# Preset options:
#   - 15 minutes before
#   - 1 hour before
#   - 1 day before
#   - 1 week before
#
class EventReminder < ApplicationRecord
  # Preset reminder times in minutes
  PRESET_MINUTES = {
    '15 minutes' => 15,
    '1 hour' => 60,
    '1 day' => 1440,
    '1 week' => 10080
  }.freeze

  # Associations
  belongs_to :event
  belongs_to :user

  # Validations
  validates :minutes_before, presence: true, numericality: { greater_than: 0 }
  validates :remind_at, presence: true

  # Callbacks
  before_validation :calculate_remind_at

  # Scopes
  scope :pending, -> { where(sent: false).where('remind_at <= ?', Time.current) }
  scope :upcoming, -> { where(sent: false).where('remind_at > ?', Time.current) }

  # Callbacks
  after_create_commit :schedule_reminder_job

  private

  # Calculate when the reminder should be sent
  def calculate_remind_at
    return unless event && minutes_before
    self.remind_at = event.start_at - minutes_before.minutes
  end

  # Schedule background job to send the reminder
  def schedule_reminder_job
    EventReminderJob.set(wait_until: remind_at).perform_later(id)
  end
end
