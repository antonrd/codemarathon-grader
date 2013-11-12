class AddCheckerToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :checker, :string
  end
end
