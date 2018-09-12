class AddStoryUnavailable < ActiveRecord::Migration[5.2]
  def change
    add_column :stories, :unavailable_at, :datetime
  end
end
