class AddDefaultStatusToReports < ActiveRecord::Migration
  def change
  	change_column_default :reports, :status, false
  end
end
