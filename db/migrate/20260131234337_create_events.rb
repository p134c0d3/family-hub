class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.boolean :all_day, default: false
      t.string :color, default: '#3b82f6'
      t.string :visibility, default: 'public'
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Recurring events (ice_cube)
      t.text :recurrence_rule
      t.datetime :recurrence_end_at

      t.timestamps
    end

    add_index :events, :start_at
    add_index :events, :visibility
    add_index :events, [:start_at, :end_at]
  end
end
