@Open =
	HandleOpenSet: (result,questionForm,entityGroup,choice_hash,form_hash) ->
		#ensures the map question is first.
		set = _.sortBy result.get('answers'),(sort) -> sort['question_id'] #really want to do this DB side instead.
		map_question = set[0] #geo is always first in open.
		other_answers = set[1..] #get all others
		#only proceed if this question has been answered.
		if map_question.points.length

			if questionForm == 'geo_point'
				point = map_question.points.pop()
				entity = new L.Marker(new L.LatLng(point.lat,point.lng))
			else if questionForm == 'geo_polygon'
				entity = new L.Polygon map_question.points
			else if questionForm == 'geo_line'
				entity = new L.Polyline map_question.points
			#else if questionForm=='geo_circle'
			#	entity = new L.Circle(new L.LatLng(map_question.point.lat,map_question.point.lng),map_question.content.radius);

			result.set({
			  	entity: entity
				});

			prepped_lines = []
			backbone_options_hash = {}
			for answer in other_answers
				form = form_hash[answer.question_id]

				switch form
					when 'fillin'
						this_answer = answer.text
						bb_answer = this_answer
					when 'number'
						this_answer = answer.number
						bb_answer = this_answer
					when 'date'
						this_moment = moment(answer.stamp)
						this_answer = this_moment.format('L')
						bb_answer = this_moment.unix()
					when 'datetime'
						this_moment = moment(answer.stamp)
						real_moment = moment(this_moment._a)
						#refactor this.want to show survey's TZ
						this_answer = real_moment.format('L LT')+' ' + window.tz_abbr
						bb_answer = real_moment.unix()


				prepped_lines.push "<i>"+choice_hash[answer.question_id]+"</i>: " + this_answer
				backbone_options_hash["Q"+answer.question_id] = bb_answer
			result.set backbone_options_hash
			string = prepped_lines.join '<br>'
			entity.bindLabel string
			entityGroup.addLayer entity
	InitFilter: (question_id) ->
		select2_options = {placeholder: "All",allowClear: true}
		#dont show the autocompleting search unless there are enough results
		select2_options['dropdownCssClass'] = "no-search"
		$("#Q#{question_id}").select2(select2_options)
	InitChronQuestion: (question_id) ->
		$("#Q#{question_id}").dateRangeSlider {arrows:false}
	InitNumberQuestion: (question_id) ->
		$("#Q#{question_id}").editRangeSlider {arrows:false}
	InitMapQuestion: (area_bounds,question,mapname,osm,noZoom) ->
		bounds = new L.LatLngBounds(area_bounds.sw_bounds, area_bounds.ne_bounds)

		if noZoom
			options = {zoomControl:false}
		else
			options = {}

		if mapname
			map = new L.Map mapname, options
		else
			map = new L.Map 'map', options

		if osm
			map.addLayer osm
		else
			osm = new L.TileLayer(osmUrl,{minZoom:2,maxZoom:18,attribution:osmAttrib,detectRetina:true})
			map.addLayer osm
		map.fitBounds bounds
		baseMaps = {
      		"Base OSM": osm,
	    	"Bing Aerial":window.bing
	    }

    	layersControl = new L.Control.Layers baseMaps
    	map.addControl new L.Control.Scale
		map.addControl layersControl
		window.layer_c = layersControl
		question.set {'map':map}

		return map
	HideDrawControls: ->
		$("#reset_area").show()
		$(".leaflet-control-draw").hide();
		$('.draw_control_active').removeClass('draw_control_active')
	HandleCreatedEntity: (question,entity) ->
		#Called after a leaflet.draw shape is created.
		question.set {'entity':entity}
		Open.HideDrawControls()
		$('.leaflet-control-pointsetter').fadeIn('fast')
		window.dirty = true
		window.entity = entity
	GetLabelsForFields: (questions) ->
		choices_hash = {}

		for answer in questions
			choices_hash[answer.id] = answer.label
		return choices_hash
	InitShow: (survey,hideControls,hideAttrib,mapname) ->
		if mapname
			map = new L.Map mapname
		else
			map = new L.Map 'map'

		if hideAttrib
			osm = new L.TileLayer osmUrl,{minZoom:8,maxZoom:18,detectRetina:true}
		else
			osm = new L.TileLayer osmUrl,{minZoom:8,maxZoom:18,detectRetina:true,attribution:osmAttrib}

		bounds = new L.LatLngBounds [survey.area.sw.lat,survey.area.sw.lng], [survey.area.ne.lat,survey.area.ne.lng]
		window.bounds = bounds
		map.fitBounds bounds
		map.addLayer osm

		layersControl = new L.Control.Scale

		group = new L.LayerGroup

		DrawFinalizedGrid map,group, survey.area.grids,Grids
		if not hideControls
			baseMaps = {
				"Base OSM": osm,
				"Bing Aerial":window.bing
			}
			overlayMaps = {
				"Grid Overlay": group
			}

			layersControl = new L.Control.Layers baseMaps,overlayMaps

			map.addControl layersControl
			window.layer_c = layersControl
		return map
	QuestionIsUnfinished: (answer) ->
		if answer is undefined
			return true
		else
			switch answer.form
				when "fillin" then test = (answer.text=="")
				when "number" then test =  (answer.number=="")
				when "date" then test = (answer.stamp=="")
				when "datetime" then test = (answer.stamp=="")
			return test
	AddExistingQuestions: (questions) ->
		for question in questions
			newQuestion = new Question(question);
			Questions.add([newQuestion]);
			q_to_pass = newQuestion.toJSON()
			q_to_pass.cid = newQuestion.cid
			#template and append
			html = _.template($("#base_template").html(),{question:q_to_pass});
			$(html).appendTo("#questions");

			#make active and show
			$("#"+newQuestion.cid).show();

			#/tie new model instance to templated dom object.
			newQuestion.set({obj:$("#"+newQuestion.cid)});
			$("#"+newQuestion.cid).find('select').val(question.form)
	SwapQuestionToType: (domref) ->
	    model = Questions.get($(domref).closest('li').attr('id'))
	    model.set({form:domref.val()})
	AddFinishedEntityGroup:(map, entityGroup,map_form) ->
		map.addLayer(entityGroup); #Add the created entity group

		window.layer_c.addOverlay(entityGroup,form_to_noun[map_form]);

		#pans on map entity clicks
		entityGroup.on 'click', (e) ->
			if map_form=='geo_point'
			  map.panTo(e.layer.getLatLng());
			else
			  map.panTo(thisCentroid(e.layer));

	InitEntryDisplay:(url)->
		#Sets up a new Collection to query from the correct endpoint.
		Spresult = Backbone.Model.extend({});

		SpresultQueryableCollection = Backbone.QueryCollection.extend({
		    model: Spresult
		});
		Spresults = new SpresultQueryableCollection();
		Spresults.url = url;

		return Spresults
	HandleFetchedEntries:(Spresults,entityGroup,map_form,choice_hash,form_hash) ->
		#Called directly after a sucessful fetch.
		entityGroup.clearLayers()

		for result in Spresults.models
			Open.HandleOpenSet(result,map_form,entityGroup,choice_hash,form_hash)

		return Spresults

	GetFormsForFields:(questions) ->
		hash = {}
		for question in questions
			hash[question.id] = question.form
		return hash
	HandleExistingManualSet: (collection,questionForm,choice_hash,form_hash,map) ->
		entityGroup = new L.LayerGroup()
		_.each collection.models, (entry) ->
			set = _.sortBy entry.get('answers'),(sort) -> sort['question_id']
			map_question = set[0] #geo is always first in open.
			other_answers = set[1..] #get all others
			#only proceed if this question has been answered.
			if map_question.points.length

				if questionForm == 'geo_point'
					point = map_question.points.pop()
					entity = new L.Marker(new L.LatLng(point.lat,point.lng),{icon:window.green_icon})
				else if questionForm == 'geo_polygon'
					entity = new L.Polygon map_question.points,sorted_path
				else if questionForm == 'geo_line'
					entity = new L.Polyline map_question.points,sorted_path

				prepped_lines = []
				for answer in other_answers
					form = form_hash[answer.question_id]

					switch form
						when 'fillin'
							this_answer = answer.text
						when 'number'
							this_answer = answer.number
						when 'date'
							this_answer = moment(answer.stamp).format('L')
						when 'datetime'
							this_moment = moment(answer.stamp)
							real_moment = moment(this_moment._a)
							#refactor this.want to show survey's TZ
							this_answer = real_moment.format('L LT')+' ' + window.tz_abbr


					prepped_lines.push "<i>"+choice_hash[answer.question_id]+"</i>: " + this_answer
				string = prepped_lines.join '<br>'
				entity.bindLabel string
				entityGroup.addLayer entity
			map.addLayer entityGroup
	InitWhiteStrip:() ->
		$("#show_upload").click =>
			if ($("#report_title").val()=="")
				alert("Enter a report title")

			else
				$('input[name=title]').val($("#report_title").val())
				$('#step1_report').hide()
				$("#upload_section").slideDown('fast')


		$("#show_manual").click =>
			if ($("#report_title").val()=="")
				alert("Enter a report title")
			else
				$('input[name=title]').val($("#report_title").val())
				$("#manual_form").click();

		$('#uploadModal').on 'hidden',(e) ->
			$('#step1_report').show()
			$("#upload_section").hide()

		$("#flip").click =>
			thisdomref = $("#flip")
			if (thisdomref.find('span').text()=='Show Details')
				$("#overview_collapsible").slideDown 'slow', =>
					window.so_map.invalidateSize();
					window.so_map.fitBounds(bounds);
				thisdomref.find('span').text('Hide Details');
				$("#flip i").removeClass('icon-chevron-down').addClass('icon-chevron-up');

			else
				$("#overview_collapsible").slideUp('slow');
				thisdomref.find('span').text('Show Details');
				$("#flip i").removeClass('icon-chevron-up').addClass('icon-chevron-down');

	InitManageSection:(existing_collaborators,ManagementSection,url) ->
		Collaborator = Backbone.Model.extend();
		CollaboratorCollection = Backbone.Collection.extend({
			model: Collaborator
			url: url
		 });

		Collaborators = new CollaboratorCollection()

		CView = new ManagementSection({
    		collection: Collaborators
  		});

  		Collaborators.reset(existing_collaborators);
		$("#survey_public").click =>
    		$('#public_save').slideDown('fast');
	RepaintIndexLabels: ->
		$('.num').each (index,obj) =>
			$(obj).find('span').text((index+1))
	AddQuestion: (form) ->
		#prep new model instance & add to collection
		newQuestion = new Question({'form':form});
		Questions.add([newQuestion])
		q_to_pass = newQuestion.toJSON()
		q_to_pass.cid = newQuestion.cid

		#template and append
		html = _.template($("#base_template").html(),{question:newQuestion});
		$(html).appendTo("#questions");

		#make active and show
		$("#"+newQuestion.cid).addClass('active_question').show();

		#tie new model instance to templated dom object.
		newQuestion.set({obj:$("#"+newQuestion.cid)})
		Questions.trigger('add') #we trigger again, since LI is now available.
		#$("#"+newQuestion.cid).ScrollTo {duration: 1000, easing: 'linear'}