# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # Core authentication
      t.string :email, null: false
      t.string :password_digest, null: false

      # Profile information
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :city, null: false

      # Role and status
      t.string :role, null: false, default: 'member'
      t.string :status, null: false, default: 'active'

      # Password management
      t.boolean :password_changed, null: false, default: false

      # User preferences
      t.string :color_mode, null: false, default: 'system'
      t.boolean :notify_in_app, null: false, default: true
      t.boolean :notify_email, null: false, default: true
      t.boolean :notify_push, null: false, default: false

      # Theme preference (references themes table, created later)
      t.bigint :selected_theme_id

      # Encryption
      t.string :encryption_key_salt

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :status
  end
end
