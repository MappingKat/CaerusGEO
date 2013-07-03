themap = @report.survey.serializing_answer_map
json.array!(@spresults) do |entry|
  json.(entry, :id,:uid, :status)
  json.answers entry.answers do |answer|
    json.(answer, :id, :question_id, themap[answer.question_id] )
  end
end