@EntryServices =
	UpdateDrawTool:(thismap) ->
		text = '<p><span style="font-size: 18px;">| </span> Add ' + thismap.control_name + '</p>'
		$("a.leaflet-control-draw-polygon").append(text);
		$("a.leaflet-control-draw-marker").append(text);
		$("a.leaflet-control-draw-polyline").append(text);
	UpdateProgressBar:() ->
		newCount = parseInt($("#completed_count").text());
		newPercent = ((newCount/window.full_count)*100)+"%";
		$('.bar').css('width',newPercent);
	InitUploadedEntryTool: (url)->
		EntryServices.UpdateProgressBar();

		thismap = form_to_nameset[window.map_form]
		$("#pending").text(thismap.pending_text);
		$("#ready").text('Finish with the '+ thismap.entity_name + " button on the map.")

		select2_options = {placeholder: "Select a response"}
		if $('option').length < 15
			select2_options['dropdownCssClass'] = "no-search";


		ShowWarning = () ->
			$('.leaflet-control-pointsetter').popover {'placement':'bottom','title':'Error','trigger' : 'manual','content': "Please save this map question's answer first"}
			$('.leaflet-control-pointsetter').popover 'show'
			setTimeout () ->
				$('.leaflet-control-pointsetter').popover('hide')
			,3000


		$("#e1").select2 select2_options
		$("#e1").on "change", (e) ->
			if window.dirty
			  ShowWarning();
			else
			  EntryServices.LoadResult(e.val); #Load this requested answer set

		firstval = parseInt($("#e1 option[value!='']").first().val())
		$("#e1").select2 "val", firstval #Set the select2box to the first one.
		EntryServices.LoadResult firstval  #and load it.

		$("#save_finish_button").click (e) ->
			if window.dirty
			  ShowWarning();

			else
			  window.location = url;

			return false;
		EntryServices.UpdateDrawTool(thismap);

	CollectManualAnswers:() ->
		answerset = [];
		for question in questions.models
			form = question.get('form')
			jquery_obj = $("#"+question.get('id'))
			if form=='fillin'
				answer = {'text':jquery_obj.find('.answer').val()};
			else if form=='number'
				answer = {'number':jquery_obj.find('.answer').val()};
			else if (_.include(['date','datetime'],form))
				answer = {'stamp':jquery_obj.find('.answer').val()}
			else if (form=='geo_point' || form=='geo_polygon' || form=='geo_line' || form=='geo_circle')
				if window.entity == undefined
					answer = undefined;
				else
					if (form=='geo_polygon' || form=='geo_line')
						answer = {'points':window.entity.getLatLngs()}
					else
						answer = {'points':[window.entity.getLatLng()]}
			if answer
				answer['form'] = form
				answer['question_id'] = question.get('id')

			answerset.push answer
		return answerset
	InitManualEntryTool: (url,area_bounds,grids) ->
		$("#save_finish_button").attr('href',url);

		$("#new_respondent_button").click (url) ->
			$("#entry_area,#questions").fadeIn('fast');
			$("#done_with_respondent_button").removeClass('disabled')
			$("#save_indicator").hide();
			$(this).hide();
			return false

		map = EntryServices.HandleQuestionSetup(questions,'manual',area_bounds,grids)
		#Get the existing answers for this survey's map questions.

		Spresults.fetch {
			success: (collection,response,xhr) ->
				if collection.models.length
					choice_hash = Open.GetLabelsForFields(questions.toJSON());
					form_hash = Open.GetFormsForFields(questions.toJSON());
					existing_group = Open.HandleExistingManualSet(collection,window.map_form,choice_hash,form_hash,map);
			error:(collection,response,options) ->
		    	alert('Sorry, there was an error retrieving existing entries.');
		}

		$('.accordion-toggle').prepend('Adjust ');
		thismap = form_to_nameset[window.map_form]

		EntryServices.UpdateDrawTool(thismap);

		$("#done_with_respondent_button").click ->
			answers = EntryServices.CollectManualAnswers();
			notReady = _.any answers,(question) ->
			  return Open.QuestionIsUnfinished(question)

			if notReady
				alert("You must fill in all answers for this respondent.")
				return false;

			successFunc = (response) ->
				window.count++;
				$("#this_quantity").text(window.count + " Entries Created");
				#clean section
				if window.map_form=='geo_point'
					window.entity.dragging.disable(); #The current marker is now set.Don't let it be draggable anymore
					window.entity.setIcon(window.green_icon);

				else
					window.entity.editing.disable();
					window.entity.dragging.disable();
					window.entity.setStyle(sorted_path);

				window.entity = undefined;
				$('#questions input[type=text]').val(''); #clear fillin questions.
				$('#questions input[type=number]').val('');

				#end clean
				$("#done_with_respondent_button").addClass('disabled');
				$("#new_respondent_button").show(); #show new respondent button;
				$("#save_indicator").fadeIn('fast');
				$(".leaflet-control-draw").fadeIn('fast'); #Bring back drawn controls
				$("#entry_area,#questions").fadeOut('fast');
			errorFunc = (error) ->
				alert('Encountered an error saving.');

			Spresults.create {'answers' : answers },{success:successFunc,error:errorFunc}
			return false

	HandleQuestionSetup: (questions,method,area,grids) ->
		map = null
		_.each questions.models,(question) ->
			type = question.get('form')
			template_payload = question.toJSON()
			thisform = question.get('form')
			if thisform in ['geo_point','geo_circle','geo_polygon','geo_line']
				mapname = 'map';
				osm = new L.TileLayer(osmUrl,{minZoom:0,maxZoom:18,attribution:osmAttrib});
				map = Open.InitMapQuestion area,question,mapname,osm,true
				zoomControl = new L.Control.Zoom();
				zoomControl.setPosition('topright');
				map.addControl(zoomControl);
				GridServices.DrawAGrid(map,grids,osm);
				entity_name = form_to_nameset[thisform].entity_name
				if method == 'uploaded'
					map.addControl(new L.Control.Pointsetter({entity_name:entity_name}));

				if type == 'geo_point'
					SocialPerception.AddPointControl(map);
					map.on 'draw:marker-created', (e) ->
						map.addLayer(e.marker);
						e.marker.dragging.enable();
						if method == 'uploaded'
							Open.HandleCreatedEntity question, e.marker
							$("#pending").hide();
							$("#ready").show();
						else
							Open.HideDrawControls();
							window.entity = e.marker;
				else if type=='geo_line' or type=='geo_polygon'

					if type=='geo_polygon'
						SocialPerception.AddPolygonControl(map)

					else
						SocialPerception.AddPolylineControl(map)

					map.on 'draw:poly-created',  (e) ->
						map.addLayer(e.poly);
						e.poly.dragging = new L.Handler.PolyDrag(e.poly);
						e.poly.dragging.enable();
						e.poly.editing.enable(); #enable after-the-fact vertex editing
						e.poly.on 'dragend',() ->
						  e.poly.editing.enable(); #enable after-the-fact vertex editing


						if method == 'uploaded'
							Open.HandleCreatedEntity(question,e.poly);
							$("#pending").hide();
							$("#ready").show();
						else
							Open.HideDrawControls();
							window.entity = e.poly;

				#question.set {'map':map}

				#Finals
				if method == 'uploaded'
					map.on 'drawing',(e) ->
						$("#instructions").hide();
						$("#pending").show();
			else
				html = _.template($("#"+type+"_template").html(),template_payload);
				$(html).appendTo("#questions");
				if method == 'uploaded'
					question.set({'jquery_obj':$("#"+question.get('id'))});
				else
					if question.get('form') == 'date'
						chrono_options = {pickTime: false}
						$('#'+ question.get('id') + ' .chronopicker').datetimepicker(chrono_options);

					else if question.get('form') == 'datetime'
						chrono_options = {}
						$('#'+ question.get('id') + ' .chronopicker').datetimepicker chrono_options
		return map
	HandleLocationData:() ->
		$("#instructions").hide()
		if window.map_form == 'geo_point'
			points = [window.entity._latlng]
		else
			points = window.entity._latlngs
		stuff = _.template $("#loc_template").html(), { points: points }
		$("#location_data").html(stuff).show();
	LeaveResult:(callback) ->
		#collect answers
		thisentry = Spresults.get window.current_spresult_id
		_.each questions.models,(question) ->
			this_model = _.filter thisentry.get('answers'), (answer) ->
				answer.question_id==question.get('id')
			this_model = this_model[0];
			thisform = question.get('form');

			if _.include ['geo_point','geo_circle','geo_polygon','geo_line'],thisform

				entity = question.get('entity');

				if thisform=='geo_point' && entity?
					this_model['points'] = [entity.getLatLng()]

				if (_.include ['geo_polygon','geo_line'],thisform) && entity?
					this_model['points'] = entity.getLatLngs()
		#end
		#refactor to use Spresults.get(window.current_spresult_id).hasChanged('answers')
		#Set answers from pointsetter button, get rid of collect answers.
		#To decline changes, use previousAttributes()  -although we dont do that yet.

		if (window.dirty)
			current_model = Spresults.get(window.current_spresult_id);
			current_model.save {}, {
			success:() ->
				#console.log('Saved ' + window.current_spresult_id);
				window.dirty = false;              #need here too?
				EntryServices.HandleLocationData();
				$("#completed_count").text(parseInt($("#completed_count").text())+1);
				EntryServices.UpdateProgressBar();

				#finish
				id = window.current_spresult_id
				existing = $('option[value="'+id+'"]').html(); #Get element's html
				newver = existing.replace('remove','ok'); #change FA icon class.
				$('option[value="'+id+'"]').html(newver);# Change existing in old select
				$("#e1").select2('val',id) #Update selected in view;


				if _.include ['geo_polygon','geo_line'], window.map_form
					window.entity.editing.disable()
					window.entity.setStyle(sorted_path)
				else
					window.entity.setIcon window.green_icon

				window.entity.dragging.disable();

				if typeof callback is 'function'
					callback()
			,
			error: () ->
				alert('there was an error.')
			}

		else
			#console.log('no need - not dirty');

	InitUploadedModel:()->
		obj = Backbone.Model.extend {
			initialize: () ->
				this.on "change:answer", (model,name) ->
					form = this.get('form');
					answer = this.get('answer');
					q_id = this.get('id')
					if answer
						#if there an answer actually present.On first load, there isnt.
						if ((form=='fillin' && answer['text']!=null) || (form!='fillin' && !_.isEmpty(answer['points'])) || (form=='number' && answer['number']!=null) || (form=='date' && answer['stamp']!=null) || (form=='datetime' && answer['stamp']!=null))
							#is the answer actually filled in.

							if (form=='fillin')
								$("#"+q_id).find('input').val(answer['text']);
							else if (form=='number')
								$("#"+q_id).find('input').val(answer['number']);
							else if (form=='date')
								thisone = moment(answer['stamp']).format('L')
								$("#"+q_id).find('input').val(thisone);
							else if (form=='datetime')
								this_moment = moment(answer['stamp']);
								real_moment = moment(this_moment._a);
								#refactor this.want to show survey's TZ
								this_answer = real_moment.format('L LT')+' ' + window.tz_abbr;
								thisone = this_answer;
								$("#"+q_id).find('input').val(thisone);
							else if _.include ['geo_point','geo_polygon','geo_line','geo_circle'],form
								map = this.get('map');
								thesepoints = answer['points'];
								if form=='geo_point'
									entity = new L.Marker([thesepoints[0].lat,thesepoints[0].lng],{icon:window.green_icon});
									center = entity.getLatLng();
								else if (form=='geo_polygon')
									entity = new L.Polygon(thesepoints);
									center = thisCentroid(entity);
								else if (form=='geo_line')
									entity = new L.Polyline(thesepoints);
									center = thisCentroid(entity);

								this.set {'entity':entity}
								map.addLayer(entity);
								map.panTo(center)
								window.entity = entity;
		}
		return obj

	LoadResult:(id) ->
		#Clean
		_.each questions.models,(question) ->
			question.set {'answer':null}
			thisform = question.get('form')
			if _.include ['geo_point','geo_circle','geo_polygon','geo_line'], thisform
				entity = question.get('entity');
				if (entity)
					question.get('map').removeLayer(entity); #remove current entity from map.
					question.set({'entity':null});

		window.entity = false;

		#set up on first execution,which is automatically off page load.
		if !$("#questions li").length
			EntryServices.HandleQuestionSetup(questions,'uploaded',window.area,window.grids)
			$('input.answer').attr('disabled','disabled');


		test_grab = Spresults.get(id);

		if test_grab
			test_grab.launchOn()
		else
			result = new Spresult();
			result.id = id;
			result.fetch {
				success: (model, response) ->
					Spresults.add model, {silent: true}
					model.launchOn();
			}
	InitUploadedSpresult:(url) ->
		obj = Backbone.Model.extend {
			urlRoot:url,
			launchOn:() ->
				theseanswers = this.get('answers')
				window.current_spresult_id = this.get('id')
				$("#respondent_id").val this.get('uid')
				window.dirty = false
				_.each theseanswers, (answer) ->
					mid = answer['question_id']
					question = questions.where({'id':mid})[0]
					question.set {'answer':answer }
				if window.entity
					$(".leaflet-control-draw").hide 'fast'
					EntryServices.HandleLocationData()
				else
					$("#location_data").empty()
					$(".leaflet-control-draw,#instructions").show()
				$('.leaflet-control-pointsetter').hide 'fast'
		}
		return obj