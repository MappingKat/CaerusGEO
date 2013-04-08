class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.string :text
      t.boolean :referenced
      t.references :spresult
      t.references :question

      t.timestamps
    end
    add_index :answers, :spresult_id
    add_index :answers, :question_id
  end
end
