class AddTimeZoneToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :time_zone, :string
  end
end
