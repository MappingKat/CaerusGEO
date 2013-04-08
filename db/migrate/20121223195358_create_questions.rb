class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :index
      t.string :label
      t.string :form
      t.string :note
      t.references :survey

      t.timestamps
    end
    add_index :questions, :survey_id
  end
end
