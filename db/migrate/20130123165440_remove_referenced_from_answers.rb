class RemoveReferencedFromAnswers < ActiveRecord::Migration
  def up
    remove_column :answers, :referenced
  end

  def down
    add_column :answers, :referenced, :boolean
  end
end
