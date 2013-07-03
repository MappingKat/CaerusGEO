@Open =
	HandleOpenSet: (result, questionForm, entityGroup, choice_hash, form_hash) ->
		#called from Analyze.
		return Open.HandleUnifiedSet(result, questionForm, choice_hash, form_hash, true, entityGroup, false, false) 
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
	AddFinishedEntityGroup:(map, entityGroup,map_form) ->
		map.addLayer(entityGroup); #Add the created entity group
		form_to_noun = {
  		"geo_point" : "Markers",
  		"geo_line": "Paths",
  		"geo_polygon": "Areas"
		}
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

		Collaborators = new CollaboratorCollection(existing_collaborators)

		CView = new ManagementSection({
    		collection: Collaborators
  		});

		$("#survey_public").click =>
    		$('#public_save').slideDown('fast');
	HandleUnifiedSet: (entry, questionForm, choice_hash, form_hash, prepareQueryHash, entityGroup, marker_opts, poly_opts, needSort, includeEntryID, extra_options) ->
		set = entry.get('answers')
		if needSort #new created instances need the sort.
			set = _.sortBy set, (answer) ->
				return parseInt(answer.question_id)

		map_question = set[0] #geo is always first in open.
		other_answers = set[1..] #get all others
		if questionForm == 'geo_point'
			point = map_question.points[0]
			entity = new L.Marker [point.lat, point.lng], marker_opts
		else if questionForm == 'geo_polygon'
			entity = new L.Polygon map_question.points, poly_opts
		else if questionForm == 'geo_line'
			entity = new L.Polyline map_question.points, poly_opts
	
		prepped_lines = []
		if prepareQueryHash
			entry.set({
		  	entity: entity
			})
			backbone_options_hash = {}
		for answer in other_answers
			form = form_hash[answer.question_id]

			switch form
				when 'fillin'
					this_answer = answer.text
					if prepareQueryHash
						bb_answer = this_answer
				when 'number'
					this_answer = answer.number
					if prepareQueryHash
						bb_answer = this_answer
				when 'date'
					this_moment = moment(answer.stamp)
					this_answer = this_moment.format('L')
					if prepareQueryHash
						bb_answer = this_moment.unix()
				when 'datetime'
					this_moment = moment(answer.stamp)
					real_moment = moment(this_moment._a)
					#refactor this.want to show survey's TZ
					this_answer = real_moment.format('L LT') + ' ' + window.tz_abbr
					if prepareQueryHash
						bb_answer = real_moment.unix()


			prepped_lines.push "<i>" + choice_hash[answer.question_id] + "</i>: " + this_answer
			if prepareQueryHash
				backbone_options_hash["Q"+answer.question_id] = bb_answer

		if includeEntryID and entry.get('uid')
			prepped_lines.push("<br>Entry ID: #{entry.get('uid')}")

		if prepareQueryHash
			entry.set backbone_options_hash
		string = prepped_lines.join '<br>'
		entity.bindLabel string
		entityGroup.addLayer entity
		if extra_options
			L.Util.setOptions(entity,extra_options)
		return entity
