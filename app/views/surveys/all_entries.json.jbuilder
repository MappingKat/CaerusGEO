themap = @survey.serializing_answer_map
json.array!(@survey.all_entries) do |entry|
	json.answers entry.answers do |answer|
		json.(answer , :question_id, themap[answer.question_id] )
	end
end