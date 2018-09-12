class HotnessModToFloat < ActiveRecord::Migration[5.2]
  def change
    change_column :tags, :hotness_mod, :float
  end
end
