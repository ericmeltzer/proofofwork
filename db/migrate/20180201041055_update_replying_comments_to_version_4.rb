class UpdateReplyingCommentsToVersion4 < ActiveRecord::Migration[5.2]
  def change
    update_view :replying_comments, version: 4, revert_to_version: 3
  end
end
