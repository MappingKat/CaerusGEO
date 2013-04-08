class AddStampToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :stamp, :datetime
  end
end
