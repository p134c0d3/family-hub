class AddMissingColumnsToThemes < ActiveRecord::Migration[8.1]
  def change
    add_column :themes, :description, :text
    add_column :themes, :is_active, :boolean
  end
end
