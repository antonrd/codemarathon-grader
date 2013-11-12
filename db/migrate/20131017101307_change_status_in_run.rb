class ChangeStatusInRun < ActiveRecord::Migration
  def up
    change_column :runs, :status, :string, limit: 32
  end

  def down
    change_column :runs, :status, :string, limit: 1024
  end
end
