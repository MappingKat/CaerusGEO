class CreateCollaborators < ActiveRecord::Migration
  def change
    create_table :collaborators do |t|
      t.string :email
      t.references :survey

      t.timestamps
    end
    add_index :collaborators, :survey_id
  end
end
