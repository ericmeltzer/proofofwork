class AddStoriesUserIndex < ActiveRecord::Migration[5.2]
  def change
    add_index "stories", [ "user_id" ]
  end
end
