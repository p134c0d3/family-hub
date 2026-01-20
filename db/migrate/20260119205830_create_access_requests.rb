# frozen_string_literal: true

class CreateAccessRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :access_requests do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :city, null: false
      t.string :status, null: false, default: 'pending'
      t.references :reviewed_by, foreign_key: { to_table: :users }, null: true
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :access_requests, :email
    add_index :access_requests, :status
  end
end
