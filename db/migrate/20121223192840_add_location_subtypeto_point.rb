class AddLocationSubtypetoPoint < ActiveRecord::Migration
  def up
  	change_table(:points) do |t|
  		t.string   :location_subtype
  	end
  end

  def down
  end
end
