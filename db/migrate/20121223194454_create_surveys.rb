class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :title
      t.string :description
      t.boolean :status
      t.references :user

      t.timestamps
    end
    add_index :surveys, :user_id
  end
end
