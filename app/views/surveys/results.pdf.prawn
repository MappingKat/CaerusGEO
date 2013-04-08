text "#{@survey.title} Results", :size => 20

mass_thing = []
fields = ["Map Reference"]
@survey.field_questions.each_with_index do |q|
	fields << "#{q.label}"
end
mass_thing << fields

@matched_results.each_with_index do |spresult,index|
	newfields = ["#{index+1}"]
	spresult.answers.includes(:question).order(:question_id).offset(1).each do |answer|
		newfields << "#{answer.content}"
	end
	mass_thing << newfields
end

t = make_table(mass_thing,:cell_style =>{ :size => 10,:borders => [],:padding => 5,:padding_bottom => 15} )
t.draw
start_new_page(:template => @front_pdf)
