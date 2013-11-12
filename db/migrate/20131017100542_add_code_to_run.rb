class AddCodeToRun < ActiveRecord::Migration
  def change
    add_column :runs, :code, :string
  end
end
