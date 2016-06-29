class ChangeRunLogTypeToMedimumText < ActiveRecord::Migration
  def change
    change_column :runs, :log, :text, limit: 16777215
  end
end
