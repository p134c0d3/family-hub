class AddMentionedUserIdsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :mentioned_user_ids, :json, default: []
  end
end
