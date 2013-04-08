class RemoveSurveyTypeFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :survey_type
  end

  def down
    add_column :users, :survey_type, :string
  end
end
