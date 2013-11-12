class AddLogToRun < ActiveRecord::Migration
  def change
    add_column :runs, :log, :text
  end
end
