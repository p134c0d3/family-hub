# frozen_string_literal: true

class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.string :name # Optional for direct chats
      t.string :chat_type, null: false # 'direct', 'group', 'public'
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :chats, :chat_type
  end
end
