@baseEditView = Backbone.View.extend {

  _answerMap: {
      fillin:'text',
      number:'number',
      date:'stamp',
      datetime:'stamp',
      geo_point:'points',
      geo_polygon:'points',
      geo_line:'points'
  },

  handleQuestionSetup: (questions, area, grids) ->
    self = this;

    map = this.map;

    questions.each (question) ->
      form = question.get('form');
      if form in ['geo_point','geo_circle','geo_polygon','geo_line']

        if form == 'geo_point'
          EntryServices.AddPointControl(map)
          map.on 'draw:marker-created', (e) ->
            self.drawInProgress = true;
            map.addLayer(e.marker);
            e.marker.dragging.enable();
            self.handleCreatedEntity(question, e.marker);
            self.$el.find("#instructions").hide();
            self.$el.find("#pending").show();
        else if form in ['geo_line','geo_polygon']
          if form == 'geo_polygon'
            EntryServices.AddPolygonControl(map);
          else
            EntryServices.AddPolylineControl(map);
          
          map.on 'draw:poly-created', (e) ->
            self.drawInProgress = true;
            map.addLayer(e.poly);
            e.poly.dragging = new L.Handler.PolyDrag(e.poly);
            e.poly.dragging.enable();
            e.poly.editing.enable(); #enable after-the-fact vertex editing
            e.poly.on 'dragend', (e) ->
              e.target.editing.enable(); #enable after-the-fact vertex editing
            
            self.handleCreatedEntity(question,e.poly);
        #Finals
          map.on 'drawing', (e) ->
            self.$el.find("#instructions").hide();
            self.$el.find("#pending").show();
      else

        html = _.template($("#"+form+"_template").html(),question.toJSON());
        $(html).appendTo(self.$el.find("#questions"));
        
        question.set({'jquery_obj':$("#"+question.get('id'))});
        
        if form == 'date'
          chrono_options = {pickTime: false};
          picker = self.$el.find('#'+ question.get('id') + ' .chronopicker').datetimepicker(chrono_options);
        else if form == 'datetime'
          chrono_options = {};
          picker = self.$el.find('#'+ question.get('id') + ' .chronopicker').datetimepicker(chrono_options);

    return map
  initMap: (mapname,noZoom) ->
    self = this;

    #init map
    osm = new L.TileLayer(osmUrl,{minZoom:0,maxZoom:18,attribution:osmAttrib, detectRetina:true});
    bounds = new L.LatLngBounds(area.sw_bounds, area.ne_bounds);
    options = if noZoom then {zoomControl:false} else {}
    actual_selector = if mapname then mapname else 'map';
    map = new L.Map(actual_selector, options);
    map.addLayer(osm);
    
    map.fitBounds(bounds)
    baseMaps = {
        "Base OSM": osm,
        "Bing Aerial":window.bing
    }

    layersControl = new L.Control.Layers(baseMaps);
    map.addControl(new L.Control.Scale);
    map.addControl(layersControl);
    zoomControl = new L.Control.Zoom();
    zoomControl.setPosition('topright');
    map.addControl(zoomControl);
    GridServices.DrawAGrid(map,grids,osm);

    return map

  showWarning: (jquery_obj, content) ->
    self = this
    self.pop_message = content
    jquery_obj.popover({
      'placement' : 'top',
      'title' : 'Error',
      'trigger' : 'manual',
      'content' : =>
        return self.pop_message
    });
    jquery_obj.popover('show');

    setTimeout =>
      jquery_obj.popover('hide')
    ,3000

  handleCreatedEntity:  (question, entity) ->
    question.set({'entity':entity})
    this.hideDrawControls();

    if question.get('form') is not 'geo_point'
      this.$el.find("#pending").hide();

  hideDrawControls: () ->
    this.$el.find(".leaflet-control-draw").hide();
    this.$el.find('.draw_control_active').removeClass('draw_control_active');

  updateDrawTool:(thismap) ->
    text = '<p><span style="font-size: 18px;">| </span> Add ' + thismap.control_name + '</p>'
    $("a.leaflet-control-draw-polygon").append(text);
    $("a.leaflet-control-draw-marker").append(text);
    $("a.leaflet-control-draw-polyline").append(text);
}


@EntryServices =
  AddPolylineControl: (map) ->
    drawControl = new L.Control.Draw {
    polygon: false,
    circle: false,
    rectangle: false,
    marker: false,
    polyline:{
      title: 'Draw your polyline.',
      allowIntersection: false,
      drawError: {
        color: '#b00b00',
        timeout: 1000
      },
      shapeOptions: {
        color: '#000000'
      }
    }
    }
    map.addControl drawControl
  AddPointControl: (map) ->
    drawControl = new L.Control.Draw({
      marker: {
        icon: edit_icon
      }
      polygon: false,
      circle: false,
      rectangle: false,
      polyline:false,

    })
    map.addControl drawControl
  AddPolygonControl: (map) ->
    drawControl = new L.Control.Draw({
      polygon: {
        title: 'Draw your polygon.',
        allowIntersection: false,
        drawError: {
          color: '#b00b00',
          timeout: 1000
        },
        shapeOptions: {
          color: '#000000'
        }
      },
      circle: false,
      rectangle: false,
      marker: false,
      polyline:false
    })
    map.addControl drawControl