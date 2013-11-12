class CreateRuns < ActiveRecord::Migration
  def change
    create_table :runs do |t|
      t.integer :user_id
      t.integer :task_id
      t.string :status, limit: 1024

      t.timestamps
    end
  end
end
