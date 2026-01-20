# frozen_string_literal: true

class CreateChatMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_memberships do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at
      t.boolean :notifications_enabled, null: false, default: true

      t.timestamps
    end

    add_index :chat_memberships, [:chat_id, :user_id], unique: true
  end
end
