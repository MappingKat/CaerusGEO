class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :title
      t.boolean :status
      t.references :survey
      t.references :user
      t.boolean :manual

      t.timestamps
    end
    add_index :reports, :survey_id
    add_index :reports, :user_id
  end
end
