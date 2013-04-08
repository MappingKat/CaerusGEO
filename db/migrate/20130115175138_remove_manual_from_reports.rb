class RemoveManualFromReports < ActiveRecord::Migration
  def up
    remove_column :reports, :manual
  end

  def down
    add_column :reports, :manual, :boolean
  end
end
