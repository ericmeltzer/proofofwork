class TagModerationLog < ActiveRecord::Migration[5.2]
  def change
    add_column :moderations, :tag_id, :integer, null: true, default: nil
  end
end
