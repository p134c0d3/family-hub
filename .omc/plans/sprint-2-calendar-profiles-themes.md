# Sprint 2: Calendar, User Profiles & Theme Management

**Created:** January 31, 2026
**Status:** ✅ IMPLEMENTED (Feb 1, 2026)
**Estimated Scope:** ~50-60 files, 3000-4000 lines of code

---

## Implementation Status

### ✅ Completed (Feb 1, 2026)

| Component | Status | Notes |
|-----------|--------|-------|
| **Gems & Dependencies** | ✅ | simple_calendar, ice_cube, Solid Queue configured |
| **Database Migrations** | ✅ | events, event_rsvps, event_reminders, themes (enhanced), user profile fields |
| **Models** | ✅ | Event, EventOccurrence, EventRsvp, EventReminder, Theme (enhanced), User (updated) |
| **Controllers** | ✅ | Events, EventRsvps, EventReminders, Calendar, Profiles, Admin::Themes, ThemeGallery |
| **Views** | ✅ | Calendar (month/week/day), Events (CRUD, forms), Profiles, Admin Themes, Theme Gallery |
| **Stimulus Controllers** | ✅ | calendar, event_form, rsvp, reminder, theme_picker |
| **Background Jobs** | ✅ | EventReminderJob, DailyReminderCheckJob |
| **Routes** | ✅ | All Sprint 2 routes configured |
| **Seed Data** | ✅ | 4 themes (Ocean Blue, Forest Green, Sunset Orange, Royal Purple) |

### 🔧 Bug Fixes Applied

| Issue | Fix |
|-------|-----|
| Missing theme columns (description, is_active) | Added migration `AddMissingColumnsToThemes` |
| CSS not loading | Fixed stylesheet_link_tag to use "tailwind" |
| Theme colors accessed incorrectly | Changed `theme.primary_color` → `theme.colors['primary']` |
| Wrong route helpers | Fixed `theme_gallery_path` → `theme_gallery_index_path` |
| Preview button using POST | Changed to GET with `link_to` |
| Theme preview showing JSON | Created visual preview.html.erb template |
| Theme CSS not applied to pages | Added `effective_theme.to_css_variables` to layouts |
| "Content missing" after preview | Added empty turbo_frame "modal" to index |
| Browser dialog on select | Removed turbo_confirm |

### 🔴 Priority Bug (Next Session)

1. **Theme colors not applying visually** - CSS variables are being set on body but theme colors aren't reflecting in the UI. Need to investigate:
   - Verify CSS variable names match Tailwind config
   - Check if Tailwind `theme-*` classes use CSS variables
   - May need to update Tailwind config to use CSS custom properties

### 🔜 What's Next (Sprint 3 Candidates)

1. **Calendar Polish**
   - Drag-and-drop event rescheduling
   - Event color picker UI
   - Recurring event editing (single vs series)

2. **Notifications**
   - Email notifications for reminders
   - Push notifications (PWA)
   - Notification center UI improvements

3. **Media Gallery Enhancement**
   - Album sharing
   - Photo tagging
   - Bulk upload

4. **Family Features**
   - Shared lists (groceries, tasks)
   - Chore assignments
   - Family tree visualization

---

## Executive Summary

This plan implements Sprint 2 of Family Hub with three major features:
1. **Calendar System** - Full calendar with month/week/day views, recurring events (ice_cube), RSVP, reminders
2. **User Profiles** - Profile editing, avatar upload, contact info, notification preferences, theme selection
3. **Theme Management** - Admin palette builder with color picker, full design system, user theme selection

### Key Decisions (From User Interview)

| Decision | Choice |
|----------|--------|
| Calendar views | Month + Week + Day |
| Recurring events | Full RRULE (ice_cube gem) |
| Reminders | In-app notifications only |
| Event permissions | Any user can create |
| Event visibility | Creator chooses (public/private) |
| RSVP options | Yes / No / Maybe / Tentative |
| Event colors | User picks color per event |
| Event form | Modal (click date → modal) |
| Calendar library | simple_calendar gem |
| Reminder presets | Both presets and custom |
| Profile fields | Basic + contact (phone, address, birthday) |
| Theme builder | Color picker + hex input (Coloris) |
| Theme depth | Full design system (15+ colors) |
| Theme selection | Dropdown + gallery page |
| Background jobs | Solid Queue (Rails 8 default) |

---

## Phase 1: Foundation & Dependencies

### 1.1 Add Required Gems

**File:** `Gemfile`

```ruby
# Calendar
gem 'simple_calendar', '~> 3.0'

# Recurring events (RRULE support)
gem 'ice_cube', '~> 0.17'

# Color picker (via importmap or vendor)
# Coloris will be added via importmap
```

**Commands:**
```bash
bundle add simple_calendar
bundle add ice_cube
bin/importmap pin coloris
```

### 1.2 Configure Solid Queue

**File:** `config/application.rb`
```ruby
config.active_job.queue_adapter = :solid_queue
```

**File:** `config/solid_queue.yml`
```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 1

development:
  <<: *default

production:
  <<: *default
  workers:
    - queues: critical
      threads: 5
      processes: 2
    - queues: default
      threads: 3
      processes: 2
```

---

## Phase 2: Database Migrations

### 2.1 Events Table

**File:** `db/migrate/XXXXXX_create_events.rb`

```ruby
class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.boolean :all_day, default: false
      t.string :color, default: '#3b82f6'  # User-picked color
      t.string :visibility, default: 'public'  # public, private
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Recurring events (ice_cube)
      t.text :recurrence_rule  # Serialized IceCube::Schedule
      t.datetime :recurrence_end_at

      t.timestamps
    end

    add_index :events, :start_at
    add_index :events, :visibility
    add_index :events, [:start_at, :end_at]
  end
end
```

### 2.2 Event RSVPs Table

**File:** `db/migrate/XXXXXX_create_event_rsvps.rb`

```ruby
class CreateEventRsvps < ActiveRecord::Migration[8.0]
  def change
    create_table :event_rsvps do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false  # yes, no, maybe, tentative
      t.text :note
      t.timestamps
    end

    add_index :event_rsvps, [:event_id, :user_id], unique: true
  end
end
```

### 2.3 Event Reminders Table

**File:** `db/migrate/XXXXXX_create_event_reminders.rb`

```ruby
class CreateEventReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :event_reminders do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :minutes_before, null: false  # e.g., 15, 60, 1440, 10080
      t.datetime :remind_at, null: false
      t.boolean :sent, default: false
      t.timestamps
    end

    add_index :event_reminders, :remind_at
    add_index :event_reminders, [:event_id, :user_id, :minutes_before], unique: true, name: 'idx_reminders_unique'
  end
end
```

### 2.4 Themes Table (Enhanced)

**File:** `db/migrate/XXXXXX_create_themes.rb`

```ruby
class CreateThemes < ActiveRecord::Migration[8.0]
  def change
    create_table :themes do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :colors, null: false, default: {}
      t.boolean :is_default, default: false
      t.boolean :is_active, default: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :themes, :name, unique: true
    add_index :themes, :is_default
  end
end
```

### 2.5 User Profile Fields

**File:** `db/migrate/XXXXXX_add_profile_fields_to_users.rb`

```ruby
class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :address, :text
    add_column :users, :birthday, :date
    add_column :users, :bio, :text
    add_reference :users, :theme, foreign_key: true
    add_column :users, :notification_preferences, :jsonb, default: {}
  end
end
```

---

## Phase 3: Models

### 3.1 Event Model

**File:** `app/models/event.rb`

```ruby
class Event < ApplicationRecord
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

  def schedule
    return nil unless recurrence_rule.present?
    IceCube::Schedule.from_hash(recurrence_rule.deep_symbolize_keys)
  end

  def schedule=(ice_cube_schedule)
    self.recurrence_rule = ice_cube_schedule&.to_hash
  end

  def recurring?
    recurrence_rule.present?
  end

  def occurrences_between(start_date, end_date)
    return [self] unless recurring?
    schedule.occurrences_between(start_date, end_date).map do |occurrence|
      EventOccurrence.new(self, occurrence)
    end
  end

  # For simple_calendar compatibility
  def start_time
    start_at
  end

  def end_time
    end_at
  end

  private

  def end_after_start
    return unless end_at && start_at
    errors.add(:end_at, 'must be after start time') if end_at <= start_at
  end
end
```

### 3.2 EventOccurrence Value Object

**File:** `app/models/event_occurrence.rb`

```ruby
# Represents a single occurrence of a recurring event
class EventOccurrence
  attr_reader :event, :start_at

  delegate :id, :title, :description, :color, :visibility, :created_by,
           :all_day, :event_rsvps, :rsvp_users, to: :event

  def initialize(event, occurrence_time)
    @event = event
    @start_at = occurrence_time
  end

  def end_at
    return nil unless event.end_at
    duration = event.end_at - event.start_at
    start_at + duration
  end

  def start_time
    start_at
  end

  def end_time
    end_at
  end

  def recurring?
    true
  end

  def occurrence?
    true
  end
end
```

### 3.3 EventRsvp Model

**File:** `app/models/event_rsvp.rb`

```ruby
class EventRsvp < ApplicationRecord
  belongs_to :event
  belongs_to :user

  STATUSES = %w[yes no maybe tentative].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :event_id, message: 'has already RSVPed' }

  scope :attending, -> { where(status: 'yes') }
  scope :not_attending, -> { where(status: 'no') }
  scope :maybe_attending, -> { where(status: %w[maybe tentative]) }

  after_create_commit :broadcast_rsvp_update
  after_update_commit :broadcast_rsvp_update

  private

  def broadcast_rsvp_update
    broadcast_replace_to event,
      target: "event_#{event.id}_rsvps",
      partial: 'events/rsvp_list',
      locals: { event: event }
  end
end
```

### 3.4 EventReminder Model

**File:** `app/models/event_reminder.rb`

```ruby
class EventReminder < ApplicationRecord
  belongs_to :event
  belongs_to :user

  PRESET_MINUTES = {
    '15 minutes' => 15,
    '1 hour' => 60,
    '1 day' => 1440,
    '1 week' => 10080
  }.freeze

  validates :minutes_before, presence: true, numericality: { greater_than: 0 }
  validates :remind_at, presence: true

  before_validation :calculate_remind_at

  scope :pending, -> { where(sent: false).where('remind_at <= ?', Time.current) }
  scope :upcoming, -> { where(sent: false).where('remind_at > ?', Time.current) }

  after_create_commit :schedule_reminder_job

  private

  def calculate_remind_at
    return unless event && minutes_before
    self.remind_at = event.start_at - minutes_before.minutes
  end

  def schedule_reminder_job
    EventReminderJob.set(wait_until: remind_at).perform_later(id)
  end
end
```

### 3.5 Theme Model (Enhanced)

**File:** `app/models/theme.rb`

```ruby
class Theme < ApplicationRecord
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :users

  # Full design system colors
  REQUIRED_COLORS = %w[
    primary secondary accent
    background surface text
    success warning error info
    border shadow
    primary_dark secondary_dark accent_dark
    background_dark surface_dark text_dark
  ].freeze

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :colors, presence: true
  validate :validate_color_keys
  validate :validate_color_formats

  scope :active, -> { where(is_active: true) }
  scope :default_theme, -> { find_by(is_default: true) }

  before_save :ensure_single_default

  def to_css_variables(dark_mode: false)
    suffix = dark_mode ? '_dark' : ''
    colors.map do |key, value|
      if dark_mode && colors["#{key}_dark"].present?
        "--color-#{key.dasherize}: #{colors["#{key}_dark"]};"
      elsif !key.end_with?('_dark')
        "--color-#{key.dasherize}: #{value};"
      end
    end.compact.join("\n")
  end

  def self.default_colors
    {
      'primary' => '#3b82f6',
      'secondary' => '#8b5cf6',
      'accent' => '#f59e0b',
      'background' => '#ffffff',
      'surface' => '#f8fafc',
      'text' => '#1f2937',
      'success' => '#10b981',
      'warning' => '#f59e0b',
      'error' => '#ef4444',
      'info' => '#3b82f6',
      'border' => '#e2e8f0',
      'shadow' => 'rgba(0,0,0,0.1)',
      'primary_dark' => '#60a5fa',
      'secondary_dark' => '#a78bfa',
      'accent_dark' => '#fbbf24',
      'background_dark' => '#111827',
      'surface_dark' => '#1f2937',
      'text_dark' => '#f9fafb'
    }
  end

  private

  def validate_color_keys
    missing = REQUIRED_COLORS.select { |k| !k.end_with?('_dark') } - colors.keys
    errors.add(:colors, "missing required keys: #{missing.join(', ')}") if missing.any?
  end

  def validate_color_formats
    colors.each do |key, value|
      next if value.start_with?('rgba') || value.start_with?('rgb')
      unless value.match?(/\A#[0-9a-fA-F]{6}\z/)
        errors.add(:colors, "#{key} must be a valid hex color or rgb/rgba value")
      end
    end
  end

  def ensure_single_default
    return unless is_default_changed? && is_default?
    Theme.where.not(id: id).update_all(is_default: false)
  end
end
```

### 3.6 User Model Updates

**File:** `app/models/user.rb` (additions)

```ruby
# Add to existing User model:

belongs_to :theme, optional: true
has_many :created_events, class_name: 'Event', foreign_key: 'created_by_id'
has_many :event_rsvps, dependent: :destroy
has_many :rsvp_events, through: :event_rsvps, source: :event
has_many :event_reminders, dependent: :destroy

# Profile validations
validates :phone, format: { with: /\A[\d\s\-\+\(\)]+\z/, allow_blank: true }
validates :birthday, comparison: { less_than: Date.current }, allow_nil: true

# Notification preferences defaults
NOTIFICATION_DEFAULTS = {
  'event_reminders' => true,
  'event_rsvp_updates' => true,
  'event_invitations' => true
}.freeze

def notification_enabled?(type)
  prefs = notification_preferences.presence || NOTIFICATION_DEFAULTS
  prefs[type.to_s] != false
end

def effective_theme
  theme || Theme.default_theme || Theme.first
end
```

---

## Phase 4: Controllers

### 4.1 Events Controller

**File:** `app/controllers/events_controller.rb`

```ruby
class EventsController < ApplicationController
  before_action :require_authentication
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authorize_event, only: [:edit, :update, :destroy]

  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @view = params[:view] || 'month'

    date_range = case @view
    when 'week' then @date.beginning_of_week..@date.end_of_week
    when 'day' then @date.beginning_of_day..@date.end_of_day
    else @date.beginning_of_month..@date.end_of_month
    end

    @events = Event.visible_to(current_user)
                   .between(date_range.begin, date_range.end)
                   .includes(:created_by, :event_rsvps)

    # Expand recurring events
    @events = expand_recurring_events(@events, date_range)
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @event = Event.new(start_at: params[:start_at] || Time.current)

    respond_to do |format|
      format.html
      format.turbo_stream { render layout: false }
    end
  end

  def create
    @event = current_user.created_events.build(event_params)

    respond_to do |format|
      if @event.save
        create_default_reminder if params[:add_reminder]
        format.html { redirect_to events_path, notice: 'Event created.' }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream { render layout: false }
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to events_path, notice: 'Event updated.' }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_path, notice: 'Event deleted.' }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@event) }
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_event
    unless @event.created_by == current_user || current_user.admin?
      redirect_to events_path, alert: 'Not authorized.'
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :start_at, :end_at, :all_day,
      :color, :visibility, :recurrence_rule, :recurrence_end_at
    )
  end

  def expand_recurring_events(events, date_range)
    expanded = []
    events.each do |event|
      if event.recurring?
        expanded.concat(event.occurrences_between(date_range.begin, date_range.end))
      else
        expanded << event
      end
    end
    expanded.sort_by(&:start_at)
  end

  def create_default_reminder
    @event.event_reminders.create(
      user: current_user,
      minutes_before: params[:reminder_minutes] || 60
    )
  end
end
```

### 4.2 Event RSVPs Controller

**File:** `app/controllers/event_rsvps_controller.rb`

```ruby
class EventRsvpsController < ApplicationController
  before_action :require_authentication
  before_action :set_event

  def create
    @rsvp = @event.event_rsvps.find_or_initialize_by(user: current_user)
    @rsvp.status = params[:status]
    @rsvp.note = params[:note]

    respond_to do |format|
      if @rsvp.save
        format.turbo_stream
        format.html { redirect_to @event }
      else
        format.html { redirect_to @event, alert: @rsvp.errors.full_messages.join(', ') }
      end
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
```

### 4.3 Event Reminders Controller

**File:** `app/controllers/event_reminders_controller.rb`

```ruby
class EventRemindersController < ApplicationController
  before_action :require_authentication
  before_action :set_event

  def create
    minutes = if params[:custom_minutes].present?
      params[:custom_minutes].to_i
    else
      params[:minutes_before].to_i
    end

    @reminder = @event.event_reminders.build(
      user: current_user,
      minutes_before: minutes
    )

    respond_to do |format|
      if @reminder.save
        format.turbo_stream
        format.html { redirect_to @event, notice: 'Reminder set.' }
      else
        format.html { redirect_to @event, alert: @reminder.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    @reminder = current_user.event_reminders.find(params[:id])
    @reminder.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@reminder) }
      format.html { redirect_to @event, notice: 'Reminder removed.' }
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
```

### 4.4 Calendar Controller

**File:** `app/controllers/calendar_controller.rb`

```ruby
class CalendarController < ApplicationController
  before_action :require_authentication

  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @view = params[:view] || 'month'

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
```

### 4.5 Profiles Controller (Enhanced)

**File:** `app/controllers/profiles_controller.rb`

```ruby
class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @user.update(profile_params)
        format.html { redirect_to profile_path, notice: 'Profile updated.' }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def update_avatar
    if @user.update(avatar: params[:avatar])
      redirect_to profile_path, notice: 'Avatar updated.'
    else
      redirect_to edit_profile_path, alert: 'Failed to update avatar.'
    end
  end

  def update_password
    if @user.authenticate(params[:current_password])
      if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        redirect_to profile_path, notice: 'Password changed.'
      else
        flash.now[:alert] = @user.errors.full_messages.join(', ')
        render :edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Current password is incorrect.'
      render :edit, status: :unprocessable_entity
    end
  end

  def update_notifications
    prefs = params[:notification_preferences]&.to_unsafe_h || {}
    @user.update(notification_preferences: prefs)
    redirect_to profile_path, notice: 'Notification preferences updated.'
  end

  def update_theme
    theme = Theme.find(params[:theme_id])
    @user.update(theme: theme)
    redirect_to profile_path, notice: 'Theme updated.'
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :address, :birthday, :bio)
  end
end
```

### 4.6 Admin Themes Controller

**File:** `app/controllers/admin/themes_controller.rb`

```ruby
module Admin
  class ThemesController < BaseController
    before_action :set_theme, only: [:show, :edit, :update, :destroy, :set_default, :preview]

    def index
      @themes = Theme.order(:name)
    end

    def show
    end

    def new
      @theme = Theme.new(colors: Theme.default_colors)
    end

    def create
      @theme = Theme.new(theme_params)
      @theme.created_by = current_user

      if @theme.save
        redirect_to admin_themes_path, notice: 'Theme created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @theme.update(theme_params)
        redirect_to admin_themes_path, notice: 'Theme updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @theme.users.any?
        redirect_to admin_themes_path, alert: 'Cannot delete theme in use.'
      else
        @theme.destroy
        redirect_to admin_themes_path, notice: 'Theme deleted.'
      end
    end

    def set_default
      @theme.update(is_default: true)
      redirect_to admin_themes_path, notice: "#{@theme.name} is now the default theme."
    end

    def preview
      respond_to do |format|
        format.json { render json: { css: @theme.to_css_variables } }
        format.html
      end
    end

    private

    def set_theme
      @theme = Theme.find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name, :description, :is_active, colors: {})
    end
  end
end
```

### 4.7 Theme Gallery Controller

**File:** `app/controllers/theme_gallery_controller.rb`

```ruby
class ThemeGalleryController < ApplicationController
  before_action :require_authentication

  def index
    @themes = Theme.active.order(:name)
    @current_theme = current_user.effective_theme
  end

  def preview
    @theme = Theme.find(params[:id])
    render json: { css: @theme.to_css_variables }
  end

  def select
    @theme = Theme.find(params[:id])
    current_user.update(theme: @theme)
    redirect_to theme_gallery_path, notice: "Theme changed to #{@theme.name}."
  end
end
```

---

## Phase 5: Background Jobs

### 5.1 Event Reminder Job

**File:** `app/jobs/event_reminder_job.rb`

```ruby
class EventReminderJob < ApplicationJob
  queue_as :default

  def perform(reminder_id)
    reminder = EventReminder.find_by(id: reminder_id)
    return unless reminder && !reminder.sent?

    event = reminder.event
    user = reminder.user

    # Skip if event was cancelled
    return if event.nil?

    # Create in-app notification
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
```

### 5.2 Daily Reminder Check Job

**File:** `app/jobs/daily_reminder_check_job.rb`

```ruby
class DailyReminderCheckJob < ApplicationJob
  queue_as :default

  # Run daily to catch any missed reminders
  def perform
    EventReminder.pending.find_each do |reminder|
      EventReminderJob.perform_now(reminder.id)
    end
  end
end
```

---

## Phase 6: Stimulus Controllers

### 6.1 Calendar Controller

**File:** `app/javascript/controllers/calendar_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "dateDisplay", "viewToggle"]
  static values = {
    date: String,
    view: { type: String, default: "month" }
  }

  connect() {
    this.updateDateDisplay()
  }

  navigate(event) {
    const direction = event.currentTarget.dataset.direction
    this.navigateToDate(direction)
  }

  navigateToDate(direction) {
    const currentDate = new Date(this.dateValue)

    switch (this.viewValue) {
      case 'month':
        currentDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1))
        break
      case 'week':
        currentDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7))
        break
      case 'day':
        currentDate.setDate(currentDate.getDate() + (direction === 'next' ? 1 : -1))
        break
    }

    this.dateValue = currentDate.toISOString().split('T')[0]
    this.loadCalendar()
  }

  changeView(event) {
    this.viewValue = event.currentTarget.dataset.view
    this.loadCalendar()
  }

  today() {
    this.dateValue = new Date().toISOString().split('T')[0]
    this.loadCalendar()
  }

  loadCalendar() {
    const url = `/calendar?date=${this.dateValue}&view=${this.viewValue}`
    Turbo.visit(url, { frame: "calendar-frame" })
  }

  updateDateDisplay() {
    if (!this.hasDateDisplayTarget) return

    const date = new Date(this.dateValue)
    const options = this.viewValue === 'day'
      ? { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
      : { year: 'numeric', month: 'long' }

    this.dateDisplayTarget.textContent = date.toLocaleDateString('en-US', options)
  }

  dateValueChanged() {
    this.updateDateDisplay()
  }

  openEventModal(event) {
    const startAt = event.currentTarget.dataset.startAt
    const url = `/events/new?start_at=${startAt}`

    // Open modal via Turbo Frame
    Turbo.visit(url, { frame: "modal" })
  }
}
```

### 6.2 Event Form Controller

**File:** `app/javascript/controllers/event_form_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recurrenceFields", "recurrenceToggle", "endDate", "allDay"]
  static values = { recurring: Boolean }

  connect() {
    this.toggleRecurrenceFields()
  }

  toggleAllDay(event) {
    const timeInputs = this.element.querySelectorAll('input[type="time"]')
    timeInputs.forEach(input => {
      input.disabled = event.target.checked
      input.closest('.form-group')?.classList.toggle('opacity-50', event.target.checked)
    })
  }

  toggleRecurrence(event) {
    this.recurringValue = event.target.checked
    this.toggleRecurrenceFields()
  }

  toggleRecurrenceFields() {
    if (this.hasRecurrenceFieldsTarget) {
      this.recurrenceFieldsTarget.classList.toggle('hidden', !this.recurringValue)
    }
  }

  setColor(event) {
    const color = event.currentTarget.dataset.color
    this.element.querySelector('input[name="event[color]"]').value = color

    // Update preview
    const preview = this.element.querySelector('.color-preview')
    if (preview) preview.style.backgroundColor = color
  }
}
```

### 6.3 RSVP Controller

**File:** `app/javascript/controllers/rsvp_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "noteField"]
  static values = { eventId: Number, currentStatus: String }

  respond(event) {
    const status = event.currentTarget.dataset.status

    // Optimistic UI update
    this.buttonTargets.forEach(btn => {
      btn.classList.remove('active', 'bg-theme-primary', 'text-white')
      btn.classList.add('bg-theme-surface')
    })
    event.currentTarget.classList.add('active', 'bg-theme-primary', 'text-white')
    event.currentTarget.classList.remove('bg-theme-surface')

    // Submit RSVP
    fetch(`/events/${this.eventIdValue}/rsvps`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify({ status: status })
    })
  }

  toggleNote() {
    this.noteFieldTarget.classList.toggle('hidden')
  }
}
```

### 6.4 Theme Picker Controller

**File:** `app/javascript/controllers/theme_picker_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"
import Coloris from 'coloris'

export default class extends Controller {
  static targets = ["colorInput", "preview", "hexInput"]
  static values = { colors: Object }

  connect() {
    this.initializeColorPickers()
  }

  initializeColorPickers() {
    Coloris.init()

    this.colorInputTargets.forEach(input => {
      Coloris({
        el: input,
        theme: 'polaroid',
        swatches: [
          '#3b82f6', '#8b5cf6', '#f59e0b', '#10b981',
          '#ef4444', '#ec4899', '#6366f1', '#14b8a6'
        ],
        alpha: false,
        formatToggle: false,
        closeButton: true
      })

      input.addEventListener('change', (e) => this.updateColor(e))
    })
  }

  updateColor(event) {
    const input = event.target
    const colorKey = input.dataset.colorKey
    const value = input.value

    // Update hex input if exists
    const hexInput = this.element.querySelector(`[data-hex-for="${colorKey}"]`)
    if (hexInput) hexInput.value = value

    // Update preview
    this.updatePreview(colorKey, value)
  }

  updateFromHex(event) {
    const input = event.target
    const colorKey = input.dataset.hexFor
    let value = input.value

    // Add # if missing
    if (!value.startsWith('#')) value = '#' + value

    // Validate hex
    if (/^#[0-9a-fA-F]{6}$/.test(value)) {
      const colorInput = this.element.querySelector(`[data-color-key="${colorKey}"]`)
      if (colorInput) {
        colorInput.value = value
        Coloris.setColor(value, colorInput)
      }
      this.updatePreview(colorKey, value)
    }
  }

  updatePreview(colorKey, value) {
    // Update CSS variable for live preview
    document.documentElement.style.setProperty(`--color-${colorKey.replace(/_/g, '-')}`, value)

    // Update preview swatch
    const swatch = this.element.querySelector(`[data-preview-for="${colorKey}"]`)
    if (swatch) swatch.style.backgroundColor = value
  }

  resetPreview() {
    // Reload page to reset CSS variables
    window.location.reload()
  }
}
```

### 6.5 Reminder Controller

**File:** `app/javascript/controllers/reminder_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["presetSelect", "customInput", "customField"]

  connect() {
    this.toggleCustomField()
  }

  toggleCustomField() {
    const isCustom = this.presetSelectTarget.value === 'custom'
    this.customFieldTarget.classList.toggle('hidden', !isCustom)
    this.customInputTarget.required = isCustom
  }

  presetChanged() {
    this.toggleCustomField()
  }
}
```

---

## Phase 7: Views

### 7.1 Calendar Views

**File:** `app/views/calendar/show.html.erb`

```erb
<div class="container mx-auto px-4 py-6" data-controller="calendar" data-calendar-date-value="<%= @date %>" data-calendar-view-value="<%= @view %>">
  <!-- Header -->
  <div class="flex items-center justify-between mb-6">
    <div class="flex items-center gap-4">
      <h1 class="text-2xl font-bold text-theme-text" data-calendar-target="dateDisplay"></h1>
      <button type="button" class="btn btn-secondary text-sm" data-action="calendar#today">Today</button>
    </div>

    <div class="flex items-center gap-2">
      <!-- Navigation -->
      <button type="button" class="btn btn-icon" data-action="calendar#navigate" data-direction="prev">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>
      <button type="button" class="btn btn-icon" data-action="calendar#navigate" data-direction="next">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </button>

      <!-- View Toggle -->
      <div class="flex rounded-card bg-theme-surface p-1 ml-4">
        <% %w[month week day].each do |view| %>
          <button type="button"
                  class="px-3 py-1 text-sm rounded-button <%= @view == view ? 'bg-theme-primary text-white' : 'text-theme-text hover:bg-theme-surface' %>"
                  data-action="calendar#changeView"
                  data-view="<%= view %>">
            <%= view.capitalize %>
          </button>
        <% end %>
      </div>

      <!-- New Event Button -->
      <%= link_to new_event_path, class: "btn btn-primary ml-4", data: { turbo_frame: "modal" } do %>
        <svg class="w-5 h-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
        </svg>
        New Event
      <% end %>
    </div>
  </div>

  <!-- Calendar Frame -->
  <%= turbo_frame_tag "calendar-frame" do %>
    <%= render "calendar/#{@view}_view", date: @date, events: @events %>
  <% end %>
</div>

<!-- Modal for event forms -->
<%= turbo_frame_tag "modal" %>
```

### 7.2 Month View Partial

**File:** `app/views/calendar/_month_view.html.erb`

```erb
<%= month_calendar(events: events, start_date: date) do |date, day_events| %>
  <div class="min-h-24 p-1 border-b border-r border-theme cursor-pointer hover:bg-theme-surface/50"
       data-action="click->calendar#openEventModal"
       data-start-at="<%= date.to_datetime.iso8601 %>">
    <div class="text-sm font-medium <%= date.today? ? 'bg-theme-primary text-white rounded-full w-7 h-7 flex items-center justify-center' : 'text-theme-text' %>">
      <%= date.day %>
    </div>

    <div class="space-y-1 mt-1">
      <% day_events.first(3).each do |event| %>
        <%= render 'events/event_pill', event: event %>
      <% end %>
      <% if day_events.size > 3 %>
        <div class="text-xs text-theme-text/60">+<%= day_events.size - 3 %> more</div>
      <% end %>
    </div>
  </div>
<% end %>
```

### 7.3 Event Form Modal

**File:** `app/views/events/_form.html.erb`

```erb
<%= form_with model: event, class: "space-y-4", data: { controller: "event-form" } do |f| %>
  <% if event.errors.any? %>
    <div class="bg-error/10 border border-error text-error px-4 py-3 rounded-card">
      <ul class="list-disc list-inside">
        <% event.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= f.label :title, class: "form-label" %>
    <%= f.text_field :title, class: "input", required: true, autofocus: true %>
  </div>

  <div class="form-group">
    <%= f.label :description, class: "form-label" %>
    <%= f.text_area :description, class: "input", rows: 3 %>
  </div>

  <div class="grid grid-cols-2 gap-4">
    <div class="form-group">
      <%= f.label :start_at, "Start", class: "form-label" %>
      <%= f.datetime_local_field :start_at, class: "input", required: true %>
    </div>
    <div class="form-group">
      <%= f.label :end_at, "End", class: "form-label" %>
      <%= f.datetime_local_field :end_at, class: "input" %>
    </div>
  </div>

  <div class="flex items-center gap-4">
    <label class="flex items-center gap-2 cursor-pointer">
      <%= f.check_box :all_day, class: "checkbox", data: { action: "event-form#toggleAllDay" } %>
      <span class="text-sm text-theme-text">All day</span>
    </label>
  </div>

  <!-- Color Picker -->
  <div class="form-group">
    <%= f.label :color, class: "form-label" %>
    <div class="flex items-center gap-2">
      <div class="color-preview w-8 h-8 rounded-button border border-theme" style="background-color: <%= event.color || '#3b82f6' %>"></div>
      <%= f.color_field :color, class: "w-12 h-8 rounded cursor-pointer", value: event.color || '#3b82f6' %>
      <div class="flex gap-1">
        <% %w[#3b82f6 #10b981 #f59e0b #ef4444 #8b5cf6 #ec4899].each do |color| %>
          <button type="button"
                  class="w-6 h-6 rounded-full border-2 border-transparent hover:border-theme-text/30"
                  style="background-color: <%= color %>"
                  data-action="event-form#setColor"
                  data-color="<%= color %>"></button>
        <% end %>
      </div>
    </div>
  </div>

  <!-- Visibility -->
  <div class="form-group">
    <%= f.label :visibility, class: "form-label" %>
    <div class="flex gap-4">
      <label class="flex items-center gap-2 cursor-pointer">
        <%= f.radio_button :visibility, 'public', class: "radio" %>
        <span class="text-sm">Public (visible to all)</span>
      </label>
      <label class="flex items-center gap-2 cursor-pointer">
        <%= f.radio_button :visibility, 'private', class: "radio" %>
        <span class="text-sm">Private (only me)</span>
      </label>
    </div>
  </div>

  <!-- Recurrence -->
  <div class="form-group">
    <label class="flex items-center gap-2 cursor-pointer">
      <%= check_box_tag :recurring, '1', event.recurring?, class: "checkbox", data: { action: "event-form#toggleRecurrence", "event-form-target": "recurrenceToggle" } %>
      <span class="text-sm text-theme-text">Repeat</span>
    </label>

    <div data-event-form-target="recurrenceFields" class="<%= 'hidden' unless event.recurring? %> mt-3 pl-6 space-y-3">
      <%= render 'events/recurrence_fields', f: f, event: event %>
    </div>
  </div>

  <div class="flex justify-end gap-2 pt-4 border-t border-theme">
    <button type="button" class="btn btn-secondary" data-action="modal#close">Cancel</button>
    <%= f.submit event.persisted? ? 'Update Event' : 'Create Event', class: "btn btn-primary" %>
  </div>
<% end %>
```

### 7.4 Profile Edit View

**File:** `app/views/profiles/edit.html.erb`

```erb
<div class="container mx-auto px-4 py-6 max-w-2xl">
  <h1 class="text-2xl font-bold text-theme-text mb-6">Edit Profile</h1>

  <%= form_with model: @user, url: profile_path, method: :patch, class: "space-y-6" do |f| %>
    <!-- Avatar -->
    <div class="card p-6">
      <h2 class="text-lg font-semibold text-theme-text mb-4">Avatar</h2>
      <div class="flex items-center gap-4">
        <div class="w-20 h-20 rounded-full bg-theme-surface overflow-hidden">
          <% if @user.avatar.attached? %>
            <%= image_tag @user.avatar, class: "w-full h-full object-cover" %>
          <% else %>
            <div class="w-full h-full flex items-center justify-center text-2xl font-bold text-theme-text/50">
              <%= @user.first_name[0] %><%= @user.last_name[0] %>
            </div>
          <% end %>
        </div>
        <%= f.file_field :avatar, accept: "image/*", class: "input", direct_upload: true %>
      </div>
    </div>

    <!-- Basic Info -->
    <div class="card p-6">
      <h2 class="text-lg font-semibold text-theme-text mb-4">Basic Information</h2>
      <div class="grid grid-cols-2 gap-4">
        <div class="form-group">
          <%= f.label :first_name, class: "form-label" %>
          <%= f.text_field :first_name, class: "input" %>
        </div>
        <div class="form-group">
          <%= f.label :last_name, class: "form-label" %>
          <%= f.text_field :last_name, class: "input" %>
        </div>
      </div>
      <div class="form-group mt-4">
        <%= f.label :email, class: "form-label" %>
        <%= f.email_field :email, class: "input" %>
      </div>
    </div>

    <!-- Contact Info -->
    <div class="card p-6">
      <h2 class="text-lg font-semibold text-theme-text mb-4">Contact Information</h2>
      <div class="form-group">
        <%= f.label :phone, class: "form-label" %>
        <%= f.telephone_field :phone, class: "input", placeholder: "+1 (555) 000-0000" %>
      </div>
      <div class="form-group mt-4">
        <%= f.label :address, class: "form-label" %>
        <%= f.text_area :address, class: "input", rows: 2 %>
      </div>
      <div class="form-group mt-4">
        <%= f.label :birthday, class: "form-label" %>
        <%= f.date_field :birthday, class: "input" %>
      </div>
    </div>

    <%= f.submit "Save Changes", class: "btn btn-primary" %>
  <% end %>

  <!-- Change Password (separate form) -->
  <div class="card p-6 mt-6">
    <h2 class="text-lg font-semibold text-theme-text mb-4">Change Password</h2>
    <%= form_with url: update_password_profile_path, method: :patch, class: "space-y-4" do |f| %>
      <div class="form-group">
        <%= f.label :current_password, class: "form-label" %>
        <%= f.password_field :current_password, class: "input", required: true %>
      </div>
      <div class="form-group">
        <%= f.label :password, "New Password", class: "form-label" %>
        <%= f.password_field :password, class: "input", required: true %>
      </div>
      <div class="form-group">
        <%= f.label :password_confirmation, class: "form-label" %>
        <%= f.password_field :password_confirmation, class: "input", required: true %>
      </div>
      <%= f.submit "Change Password", class: "btn btn-secondary" %>
    <% end %>
  </div>

  <!-- Theme Selection -->
  <div class="card p-6 mt-6">
    <h2 class="text-lg font-semibold text-theme-text mb-4">Theme</h2>
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm text-theme-text">Current: <strong><%= @user.effective_theme.name %></strong></p>
      </div>
      <div class="flex gap-2">
        <%= form_with url: update_theme_profile_path, method: :patch, class: "flex items-center gap-2" do |f| %>
          <%= f.select :theme_id, Theme.active.pluck(:name, :id), { selected: @user.theme_id }, class: "input w-48" %>
          <%= f.submit "Apply", class: "btn btn-secondary" %>
        <% end %>
        <%= link_to "Browse Themes", theme_gallery_path, class: "btn btn-secondary" %>
      </div>
    </div>
  </div>

  <!-- Notification Preferences -->
  <div class="card p-6 mt-6">
    <h2 class="text-lg font-semibold text-theme-text mb-4">Notification Preferences</h2>
    <%= form_with url: update_notifications_profile_path, method: :patch, class: "space-y-3" do |f| %>
      <% User::NOTIFICATION_DEFAULTS.each do |key, default| %>
        <label class="flex items-center gap-3 cursor-pointer">
          <%= check_box_tag "notification_preferences[#{key}]", "true", @user.notification_enabled?(key), class: "checkbox" %>
          <span class="text-sm text-theme-text"><%= key.titleize.gsub('_', ' ') %></span>
        </label>
      <% end %>
      <%= f.submit "Save Preferences", class: "btn btn-secondary mt-4" %>
    <% end %>
  </div>
</div>
```

### 7.5 Admin Theme Builder

**File:** `app/views/admin/themes/_form.html.erb`

```erb
<%= form_with model: [:admin, theme], class: "space-y-6", data: { controller: "theme-picker" } do |f| %>
  <div class="grid grid-cols-3 gap-6">
    <!-- Left: Form Fields -->
    <div class="col-span-2 space-y-6">
      <div class="card p-6">
        <h2 class="text-lg font-semibold text-theme-text mb-4">Theme Details</h2>

        <div class="form-group">
          <%= f.label :name, class: "form-label" %>
          <%= f.text_field :name, class: "input", required: true %>
        </div>

        <div class="form-group mt-4">
          <%= f.label :description, class: "form-label" %>
          <%= f.text_area :description, class: "input", rows: 2 %>
        </div>
      </div>

      <!-- Color Sections -->
      <% [
        ['Core Colors', %w[primary secondary accent]],
        ['UI Colors', %w[background surface text border]],
        ['Semantic Colors', %w[success warning error info]],
        ['Dark Mode Overrides', %w[primary_dark secondary_dark accent_dark background_dark surface_dark text_dark]]
      ].each do |section_name, color_keys| %>
        <div class="card p-6">
          <h2 class="text-lg font-semibold text-theme-text mb-4"><%= section_name %></h2>
          <div class="grid grid-cols-3 gap-4">
            <% color_keys.each do |color_key| %>
              <div class="form-group">
                <label class="form-label text-sm"><%= color_key.titleize %></label>
                <div class="flex items-center gap-2">
                  <!-- Color preview swatch -->
                  <div class="w-8 h-8 rounded border border-theme"
                       data-preview-for="<%= color_key %>"
                       style="background-color: <%= theme.colors[color_key] || Theme.default_colors[color_key] %>"></div>

                  <!-- Color picker input -->
                  <input type="text"
                         name="theme[colors][<%= color_key %>]"
                         value="<%= theme.colors[color_key] || Theme.default_colors[color_key] %>"
                         class="input w-24 coloris-input"
                         data-theme-picker-target="colorInput"
                         data-color-key="<%= color_key %>">

                  <!-- Hex input -->
                  <input type="text"
                         value="<%= theme.colors[color_key] || Theme.default_colors[color_key] %>"
                         class="input w-24 font-mono text-sm"
                         placeholder="#000000"
                         data-hex-for="<%= color_key %>"
                         data-action="input->theme-picker#updateFromHex">
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>

    <!-- Right: Live Preview -->
    <div class="col-span-1">
      <div class="card p-6 sticky top-6" data-theme-picker-target="preview">
        <h2 class="text-lg font-semibold text-theme-text mb-4">Live Preview</h2>

        <div class="space-y-4">
          <!-- Sample buttons -->
          <div class="space-y-2">
            <button class="btn btn-primary w-full">Primary Button</button>
            <button class="btn btn-secondary w-full">Secondary Button</button>
          </div>

          <!-- Sample card -->
          <div class="bg-theme-surface rounded-card p-4 border border-theme">
            <h3 class="font-medium text-theme-text">Sample Card</h3>
            <p class="text-sm text-theme-text/70 mt-1">This is how content will look.</p>
          </div>

          <!-- Status colors -->
          <div class="flex gap-2">
            <span class="badge bg-success text-white">Success</span>
            <span class="badge bg-warning text-white">Warning</span>
            <span class="badge bg-error text-white">Error</span>
            <span class="badge bg-info text-white">Info</span>
          </div>
        </div>

        <div class="mt-6 pt-4 border-t border-theme">
          <button type="button" class="btn btn-secondary w-full" data-action="theme-picker#resetPreview">
            Reset Preview
          </button>
        </div>
      </div>
    </div>
  </div>

  <div class="flex justify-end gap-2 pt-6 border-t border-theme">
    <%= link_to "Cancel", admin_themes_path, class: "btn btn-secondary" %>
    <%= f.submit theme.persisted? ? 'Update Theme' : 'Create Theme', class: "btn btn-primary" %>
  </div>
<% end %>
```

---

## Phase 8: Routes

**File:** `config/routes.rb` (additions)

```ruby
Rails.application.routes.draw do
  # ... existing routes ...

  # Calendar
  resource :calendar, only: [:show], controller: 'calendar'

  # Events
  resources :events do
    resources :rsvps, only: [:create], controller: 'event_rsvps'
    resources :reminders, only: [:create, :destroy], controller: 'event_reminders'
  end

  # Profile
  resource :profile, only: [:show, :edit, :update] do
    patch :update_avatar
    patch :update_password
    patch :update_notifications
    patch :update_theme
  end

  # Theme Gallery
  resources :theme_gallery, only: [:index] do
    member do
      get :preview
      post :select
    end
  end

  # Admin
  namespace :admin do
    # ... existing admin routes ...

    resources :themes do
      member do
        post :set_default
        get :preview
      end
    end
  end
end
```

---

## Phase 9: Seeds & Defaults

**File:** `db/seeds.rb` (additions)

```ruby
# Create default theme
Theme.find_or_create_by!(name: 'Ocean Blue') do |theme|
  theme.colors = Theme.default_colors
  theme.is_default = true
  theme.description = 'The default Family Hub theme with calming blue tones.'
end

# Create additional themes for variety
Theme.find_or_create_by!(name: 'Forest Green') do |theme|
  theme.colors = Theme.default_colors.merge(
    'primary' => '#059669',
    'secondary' => '#10b981',
    'accent' => '#fbbf24',
    'primary_dark' => '#34d399',
    'secondary_dark' => '#6ee7b7'
  )
  theme.description = 'A nature-inspired theme with green accents.'
end

Theme.find_or_create_by!(name: 'Sunset') do |theme|
  theme.colors = Theme.default_colors.merge(
    'primary' => '#f97316',
    'secondary' => '#fb923c',
    'accent' => '#fbbf24',
    'primary_dark' => '#fdba74',
    'secondary_dark' => '#fed7aa'
  )
  theme.description = 'Warm orange tones inspired by sunset.'
end
```

---

## Phase 10: Testing Checklist

### Manual Testing

- [ ] Calendar month view displays correctly
- [ ] Calendar week view displays correctly
- [ ] Calendar day view displays correctly
- [ ] Navigate between months/weeks/days
- [ ] Today button works
- [ ] Create event via modal
- [ ] Edit event
- [ ] Delete event
- [ ] Set event as all-day
- [ ] Set event color
- [ ] Set event visibility (public/private)
- [ ] Create recurring event (daily)
- [ ] Create recurring event (weekly)
- [ ] Create recurring event (monthly)
- [ ] Recurring events expand correctly on calendar
- [ ] RSVP to event (yes/no/maybe/tentative)
- [ ] RSVP updates in real-time
- [ ] Add reminder (preset)
- [ ] Add reminder (custom)
- [ ] Reminder notification received
- [ ] Edit profile basic info
- [ ] Upload avatar
- [ ] Change password
- [ ] Update notification preferences
- [ ] Select theme from dropdown
- [ ] Browse theme gallery
- [ ] Preview theme before selecting
- [ ] Admin: Create new theme
- [ ] Admin: Color picker works
- [ ] Admin: Hex input works
- [ ] Admin: Live preview updates
- [ ] Admin: Set default theme
- [ ] Admin: Delete unused theme
- [ ] Dark mode works with custom theme

---

## Implementation Order

1. **Day 1: Foundation**
   - Add gems (simple_calendar, ice_cube)
   - Configure Solid Queue
   - Create all migrations
   - Run migrations

2. **Day 2: Models**
   - Event, EventOccurrence, EventRsvp, EventReminder
   - Theme model enhancements
   - User model updates
   - Model tests

3. **Day 3: Calendar Controllers & Views**
   - CalendarController
   - EventsController (CRUD)
   - Month/week/day views
   - Event modal form

4. **Day 4: RSVP & Reminders**
   - EventRsvpsController
   - EventRemindersController
   - Background jobs
   - Real-time RSVP updates

5. **Day 5: Recurring Events**
   - ice_cube integration
   - Recurrence UI fields
   - Occurrence expansion logic

6. **Day 6: User Profiles**
   - ProfilesController enhancements
   - Profile edit form
   - Avatar upload
   - Password change
   - Notification preferences

7. **Day 7: Theme System**
   - Admin::ThemesController
   - Theme palette builder with Coloris
   - Theme gallery for users
   - Theme preview

8. **Day 8: Polish & Testing**
   - Stimulus controllers refinement
   - CSS/styling polish
   - Manual testing
   - Bug fixes

---

## Dependencies

```
simple_calendar (~> 3.0)
ice_cube (~> 0.17)
coloris (via importmap)
solid_queue (Rails 8 default)
```

---

## Notes

- All views follow existing 15px border radius convention
- All forms use existing `.input`, `.btn`, `.card` classes
- Real-time updates use existing ActionCable/Turbo Stream patterns
- Theme CSS variables match existing `--color-*` naming
- Solid Queue used instead of Sidekiq (no Redis needed)
- In-app notifications only (no ActionMailer setup required)

---

**Status:** Ready for review and approval.

*Once approved, ultrawork will execute with up to 10 parallel agents.*
