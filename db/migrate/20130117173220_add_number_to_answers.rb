class AddNumberToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :number, :float
  end
end
