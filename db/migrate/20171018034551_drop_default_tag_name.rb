class DropDefaultTagName < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:tags, :tag, from: '', to: nil)
  end
end
