class AddDefaultPublicToSurveys < ActiveRecord::Migration
	def change
	    change_column_default :surveys, :public, false
	end
end
