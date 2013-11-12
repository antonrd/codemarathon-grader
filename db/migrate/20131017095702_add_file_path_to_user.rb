class AddFilePathToUser < ActiveRecord::Migration
  def change
    add_column :users, :file_path, :string, limit: 2048
  end
end
