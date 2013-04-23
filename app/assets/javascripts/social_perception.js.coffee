@SocialPerception =
  AddPolylineControl: (map) ->
    drawControl = new L.Control.Draw {
      polygon: false,
      circle: false,
      rectangle: false,
      marker: false,
      polyline:{
        title: 'Draw your polygon.',
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
            polygon: false,
            circle: false,
            rectangle: false,
            polyline:false
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
  RepaintIndexLabels: ->
  		$('.num').each (index,obj) =>
    		$(obj).find('span').text((index+1))
  GetFreshTileUrl: ->
    new L.TileLayer(osmUrl+"?"+Math.floor(Math.random()*500),{minZoom:8,maxZoom:18,attribution:osmAttrib,detectRetina:true})
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
