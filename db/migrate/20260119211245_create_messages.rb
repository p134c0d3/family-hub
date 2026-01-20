# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent_message, foreign_key: { to_table: :messages }, null: true # for threads
      t.text :encrypted_content, null: false
      t.string :encryption_iv # initialization vector
      t.boolean :edited, null: false, default: false
      t.datetime :deleted_at # soft delete

      t.timestamps
    end

    add_index :messages, :deleted_at
    add_index :messages, [:chat_id, :created_at]
  end
end
