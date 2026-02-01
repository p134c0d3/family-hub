# frozen_string_literal: true

# Event model for Family Hub
#
# Represents a calendar event with support for recurring events via ice_cube.
# Events can be public (visible to all) or private (visible only to creator).
# Supports RSVP tracking and reminder notifications.
#
class Event < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User'
  has_many :event_rsvps, dependent: :destroy
  has_many :rsvp_users, through: :event_rsvps, source: :user
  has_many :event_reminders, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :start_at, presence: true
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: 'must be a valid hex color' }
  validates :visibility, inclusion: { in: %w[public private] }
  validate :end_after_start

  # Scopes
  scope :visible_to, ->(user) {
    where(visibility: 'public')
      .or(where(created_by: user))
      .or(where(id: EventRsvp.where(user: user).select(:event_id)))
  }
  scope :between, ->(start_date, end_date) {
    where('start_at >= ? AND start_at <= ?', start_date.beginning_of_day, end_date.end_of_day)
  }
  scope :upcoming, -> { where('start_at >= ?', Time.current).order(:start_at) }

  # Recurring events (ice_cube)
  serialize :recurrence_rule, coder: JSON

  # Get the ice_cube schedule object
  def schedule
    return nil unless recurrence_rule.present?
    IceCube::Schedule.from_hash(recurrence_rule.deep_symbolize_keys)
  end

  # Set the ice_cube schedule object
  def schedule=(ice_cube_schedule)
    self.recurrence_rule = ice_cube_schedule&.to_hash
  end

  # Check if event has recurrence rules
  def recurring?
    recurrence_rule.present?
  end

  # Get all occurrences of this event within a date range
  # For non-recurring events, returns an array with just the event itself
  # For recurring events, returns an array of EventOccurrence objects
  def occurrences_between(start_date, end_date)
    return [self] unless recurring?
    schedule.occurrences_between(start_date, end_date).map do |occurrence|
      EventOccurrence.new(self, occurrence)
    end
  end

  # Aliases for simple_calendar compatibility
  def start_time
    start_at
  end

  def end_time
    end_at
  end

  private

  # Validate that end_at is after start_at
  def end_after_start
    return unless end_at && start_at
    errors.add(:end_at, 'must be after start time') if end_at <= start_at
  end
end
