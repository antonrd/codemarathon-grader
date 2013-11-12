class AddMessageToRun < ActiveRecord::Migration
  def change
    add_column :runs, :message, :string, limit: 2048
  end
end
