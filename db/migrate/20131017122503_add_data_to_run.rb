class AddDataToRun < ActiveRecord::Migration
  def change
    add_column :runs, :data, :text
  end
end
