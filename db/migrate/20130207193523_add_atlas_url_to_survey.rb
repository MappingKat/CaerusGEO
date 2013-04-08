class AddAtlasUrlToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :atlas_url, :string
  end
end
