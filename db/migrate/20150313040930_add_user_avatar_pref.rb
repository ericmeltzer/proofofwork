class AddUserAvatarPref < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :show_avatars, :boolean, :default => false
  end
end
