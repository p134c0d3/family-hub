# frozen_string_literal: true

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
