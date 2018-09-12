class AddStoryMerging < ActiveRecord::Migration[5.2]
  def change
    add_column :stories, :merged_story_id, :integer
    add_index "stories", [ "merged_story_id" ]
  end
end
