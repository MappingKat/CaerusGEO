class CreateGrids < ActiveRecord::Migration
  def change
    create_table :grids do |t|
      t.string :name
      t.integer :index
      t.references :area

      t.timestamps
    end
    add_index :grids, :area_id
  end
end
