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
