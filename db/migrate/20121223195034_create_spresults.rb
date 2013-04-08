class CreateSpresults < ActiveRecord::Migration
  def change
    create_table :spresults do |t|
      t.references :report
      t.string :uid

      t.timestamps
    end
    add_index :spresults, :report_id
  end
end
