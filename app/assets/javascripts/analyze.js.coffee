@Analyze = 
  PrepHeat: (results) ->
    data = []
    for result in results
      entity = result.get('entity').getLatLng()
      data.push {lat:entity.lat,lon:entity.lng,value:1}
    return data
  ResetSort: (models) ->
    if window.map_form == 'geo_point'
      for model in models
        entity = model.get 'entity'
        entity.setOpacity 0
    else
      for model in models
        entity = model.get 'entity'
        entity.setStyle {"opacity":0,"fillOpacity":0}
      
  DoSort:(models) ->
    if window.map_form == 'geo_point'
      for model in models
        entity = model.get 'entity'
        entity.setOpacity 1
    else
      for model in models
        entity = model.get 'entity'
        entity.setStyle {"opacity":0.6,"fillOpacity":0.5}
  LoadData:(val,survey_path,reports_path,entityGroup,heatmapLayer,choice_hash,form_hash,questions) ->
      $("#entry_loader").show();
      if val=='All'
        Spresults = Open.InitEntryDisplay(survey_path)
      
      else 
        url = reports_path.replace('X',val);
        Spresults = Open.InitEntryDisplay(url);
      

      Spresults.fetch {
        success: =>
          $("#entry_loader").hide();
          OpenResults = Open.HandleFetchedEntries(Spresults,entityGroup,window.map_form,choice_hash,form_hash);
          if OpenResults.models.length > 0
            $("#available_count").text(OpenResults.models.length)
            Analyze.UpdateFilters(OpenResults,questions);
            $("#no_entries").hide();
            $("#counter_info").show();
            
          else 
            $("#no_entries").show();
            $("#counter_info").hide();
          
            
          Analyze.InitPage(OpenResults);
          Analyze.GetSorts(OpenResults);
          #We don't need to call sort here, as the event handlers on filters do that for us.
        
        error: =>
          alert("Sorry, there was an error loading this report's entries")

      }
  GetSorts:(OpenResults) ->
     #Build sort object
      sorted = {}

      #Loop thru each select, see if a filter is applied.If so, add to object.
      $('#sorting_box select').each ->
        value = $(this).select2('val');
        if (value!="")
          sorted[$(this).attr('id')] = $(this).select2('val');
       
      $('.numberSlider').each ->
        values = $(this).editRangeSlider("values")
        bounds = $(this).editRangeSlider("bounds")
        if values.min != bounds.min or values.max != bounds.max
          sorted[$(this).attr('id')] = {$between:[values.min-1,values.max+1]}

      $('.dateSlider').each ->
        values = $(this).dateRangeSlider("values")
        bounds = $(this).dateRangeSlider("bounds")
        if values.min.valueOf()!=bounds.min.valueOf() or values.max.valueOf()!=bounds.max.valueOf()
          first_day = moment(values.min).unix();
          last_day = moment(values.max).add('d',1).unix();
          sorted[$(this).attr('id')] = {$between:[first_day,last_day]};

     #See if a query actually exists.It's possible all the selects are on "All".
      query = !_.isEmpty(sorted);

      #If query exists, pass it to backbone, and get results of where.
      if query
        results = OpenResults.query(sorted)
      #Otherwise, just get all models.
      else
        results = OpenResults.models
      
      #Reset any existing filter.
      Analyze.ResetSort(OpenResults.models)
      #If there was a query, now apply it.
      
      Analyze.DoSort results

      if window.map_form == 'geo_point'
        heatData = Analyze.PrepHeat(results)

        testData = {
                max: 46,
                data: heatData
        };

        window.heatmap.addData(testData.data);
        window.heatmap.redraw()

      $("#visible_count").text(results.length)

  InitPage:(OpenResults) ->
      $(document).off "valuesChanging valuesChanged", ".ui-rangeSlider"
      $(document).on "valuesChanging valuesChanged", ".ui-rangeSlider", (e, data) ->
        Analyze.GetSorts(OpenResults);
      $(document).off "change", ".field_filter"
      $(document).on "change", ".field_filter", (e, data) ->
        Analyze.GetSorts(OpenResults);
  SetUpHeatMap:(map_form) ->
    if map_form=='geo_point'
      heatmapLayer = L.TileLayer.heatMap({
        radius: 13,
        opacity: 0.8
      })
      window.layer_c.addOverlay(heatmapLayer,"Heatmap")
    else
      heatmapLayer = {}
    return heatmapLayer

  InitFilters:(questions) ->
    for question in questions.models
        form = question.get('form')
        id = question.get('id')
        if form == 'fillin'
          Open.InitFilter(id);
        else if form == 'number'
          Open.InitNumberQuestion(id)
        else if form == 'date' or form == 'datetime'
          Open.InitChronQuestion(id)

  UpdateFilters:(OpenResults,questions) ->
     for question in questions.models
        form = question.get('form')
        domref = $("#Q#{question.get('id')}")
        plucks = _.uniq OpenResults.pluck("Q#{question.get('id')}")
        if form == 'fillin'
          values = _.sortBy plucks,(choice) -> choice[0].toLowerCase()
          domref.select2('val','') #wipe out this current criteria.It may not exist anymore in this report's choices.
          domref.find('.actual').remove(); #remove existing available choices.
          
          newchoices = _.template($("#choices_template").html(),{choices:values})
          domref.append newchoices #place new choices in
        
        else if form == 'number' 
          values = _.sortBy plucks,(num) -> num 
          min = values[0]
          max = values[values.length-1]
          if min == max
           max = max+1 #needs to have a range!

          try
            domref.editRangeSlider('bounds',min,max)
          catch error

          finally
            domref.editRangeSlider('bounds',min,max)
          domref.editRangeSlider('values',min,max)
        

        else if form == 'date' or form == 'datetime' 
          values = _.sortBy plucks,(num) -> num
          values = _.without values, undefined #looks to be overkill, fix for broken upload from weeks ago.
          min = values[0]
          max = values[values.length-1]
          min = moment.unix(min).sod()
          max = moment.unix(max).eod()

          if min.format("MM/DD/YYYY")==max.format("MM/DD/YYYY")
            max = max.add('d',1)
          
          realMin = min.toDate();
          realMax = max.toDate();

          domref.dateRangeSlider('values',realMin,realMax);
          domref.dateRangeSlider('bounds',realMin,realMax);
          domref.dateRangeSlider('values',realMin,realMax);