class RemoveTagFilteredByDefault < ActiveRecord::Migration[5.2]
  def change
    remove_column :tags, :filtered_by_default
  end
end
