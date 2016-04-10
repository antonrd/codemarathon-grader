class AddCheckerLangToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :checker_lang, :string
  end
end
