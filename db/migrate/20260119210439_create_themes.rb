# frozen_string_literal: true

class CreateThemes < ActiveRecord::Migration[8.1]
  def change
    create_table :themes do |t|
      t.string :name, null: false
      t.json :colors, null: false
      t.boolean :is_default, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :themes, :name, unique: true
    add_index :themes, :is_default

    # Add foreign key for selected_theme on users
    add_foreign_key :users, :themes, column: :selected_theme_id
  end
end
