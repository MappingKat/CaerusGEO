class AddDefaultStatusToSurveys < ActiveRecord::Migration
	def change
	    change_column_default :surveys, :status, false
	end
end
