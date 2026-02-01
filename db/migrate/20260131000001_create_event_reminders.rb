class CreateEventReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :event_reminders do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :minutes_before, null: false
      t.datetime :remind_at, null: false
      t.boolean :sent, default: false
      t.timestamps
    end

    add_index :event_reminders, :remind_at
    add_index :event_reminders, [:event_id, :user_id, :minutes_before], unique: true, name: 'idx_reminders_unique'
  end
end
