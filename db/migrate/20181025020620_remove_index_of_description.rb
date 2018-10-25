class RemoveIndexOfDescription < ActiveRecord::Migration[5.2]
  def change
  	remove_index "stories", name: "index_stories_on_description"
  end
end
