class PushoverSound < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :pushover_sound, :string
  end
end
