class AddPublicToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :public, :boolean
  end
end
