themap = @report.survey.serializing_answer_map
json.array!(@report.all_entries) do |json,entry|
	json.answers entry.answers do |json,answer|
		json.(answer , :question_id, themap[answer.question_id] )
	end
end