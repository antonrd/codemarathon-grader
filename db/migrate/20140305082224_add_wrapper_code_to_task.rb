class AddWrapperCodeToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :wrapper_code, :text
  end
end
