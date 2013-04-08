class AddMethodToReport < ActiveRecord::Migration
  def change
    add_column :reports, :method, :string, :limit => 1
  end
end
