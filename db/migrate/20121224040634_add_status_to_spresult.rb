class AddStatusToSpresult < ActiveRecord::Migration
  def change
    add_column :spresults, :status, :boolean
  end
end
