class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.string :city
      t.string :country
      t.string :thumbnail
      t.references :survey

      t.timestamps
    end
    add_index :areas, :survey_id
  end
end
