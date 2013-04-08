class AddBaseToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :base, :integer
  end
end
