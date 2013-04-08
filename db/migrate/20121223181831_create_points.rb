class CreatePoints < ActiveRecord::Migration
  def change
    create_table :points do |t|
      t.float :lat
      t.float :lng
      t.belongs_to :location, polymorphic: true

      t.timestamps
    end
    add_index :points, [:location_id, :location_type]
  end
end
