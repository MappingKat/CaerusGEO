text "Report Title____________________", :size => 18

move_down 12
headerrow = ["ID #"]
field_qs = @survey.field_questions
field_qs.each{|q| headerrow << "#{q.label} (#{q.short_version})" }
emptyrow = @survey.field_questions.map{|i| "" }
base_array = []
base_array << headerrow 
20.times do |i| 
	base_array << [" ",emptyrow].flatten 
end
compute = (705/field_qs.count)
table(base_array) do
	cells.padding = 4
	cells.borders = [:bottom,:top,:left, :right]
	columns(0).width = 60
	columns(0).font_style = :bold
	columns(1..50).width = compute
	row(0).border_width = 1
	row(0).font_style = :bold
	row(0).size = 11
	row(0).borders = [:bottom, :left,:right]
	column(0).borders = [:top,:bottom,:right]
	column(headerrow.length-1).borders = [:top,:bottom,:left]
	row(0).column(0).borders = [:right,:bottom]
	row(0).column(headerrow.length-1).borders = [:left,:bottom]
	row(0).border_width = 2
end

current_format = current_user.pref_us_time_format
dateformat = (current_format) ? "MM/DD/YYYY"  : "DD/MM/YYYY"
timeformat = (current_format) ? "H:MM AM/PM" : "HH:MM"           

field_map = {"fillin" => "<b>(F)</b> Enter any text", "number" => "<b>(N)</b> Enter any Number","date" => "<b>(D)</b> Enter any date in #{dateformat}","datetime" => "<b>(DT)</b> Enter a date+time in #{dateformat} #{timeformat}"}
field_array = @survey.types_used.map{|type| field_map[type] }
move_cursor_to 10
fullstring = field_array.join("    ")
text fullstring, :align => :left, :size => 9, :inline_format => true

move_cursor_to 10
text "Data Collection Worksheet | #{@survey.title}", :align => :right, :size => 10

