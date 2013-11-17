class AddLimitsToRun < ActiveRecord::Migration
  def change
    add_column :runs, :max_memory_kb, :integer
    add_column :runs, :max_time_ms, :integer
  end
end
