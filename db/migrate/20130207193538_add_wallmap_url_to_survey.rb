class AddWallmapUrlToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :wallmap_url, :string
  end
end
