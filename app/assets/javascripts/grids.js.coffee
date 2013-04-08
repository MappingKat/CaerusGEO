@GridServices = 
  DrawAGrid: (map,grid_json) ->
        group = new L.LayerGroup()
        DrawFinalizedGrid map,group, grid_json,Grids
        return group
  ResetFramer: (rectangle) ->
        these_new_bounds = rectangle.getBounds()
        DrawGrid(these_new_bounds,window.group,Grids,window.columns,window.rows); 
        marker3.setLatLng(these_new_bounds.getSouthEast())
        #ratio refresh
        NE = map.latLngToContainerPoint(these_new_bounds.getNorthEast());
        SW = map.latLngToContainerPoint(these_new_bounds.getSouthWest());
        delta_x = Math.abs(NE.x - SW.x);
        delta_y = Math.abs(NE.y - SW.y);
        window.XY_ratio = (delta_x / delta_y).toFixed(6);


        rectangle.bringToFront(); #to ensure the rectangle dragging is still available.
        GridServices.PrepBacker(rectangle) #redo shaded edges
        GridServices.SetModifyMarkers() #reset control markers
        window.page_counter.updateCount(Grids.models.length)

  bindMapMoves: (map) ->
        map.on 'movestart', (e) ->
            bounds = rectangle.getBounds();

            tl = map.latLngToContainerPoint(bounds.getNorthWest())
            br = map.latLngToContainerPoint(bounds.getSouthEast());
            newbounds = new L.Bounds(tl,br);
            this._lastBounds = newbounds;


        map.on 'move',(e) ->
            if not this._lastBounds
                return
            tl = map.containerPointToLatLng(this._lastBounds.min)
            br = map.containerPointToLatLng(this._lastBounds.max)
            newbounds = new L.LatLngBounds(tl,br);
            rectangle.setBounds(newbounds)
            GridServices.ResetFramer(rectangle)

  InitTool: (existing) ->
        options = { trackResize:false,editInOSMControl: true,editInOSMControlOptions: {position: "bottomright"}}
        map = new L.Map 'map', options


        osm = new L.TileLayer(osmUrl,{minZoom:0,maxZoom:18,attribution:osmAttrib,detectRetina:true});

        map.setView(new L.LatLng(6.319393394223436, -10.802392959594727), 13)

        if not existing
            GridServices.bindMapMoves(map)

        map.addLayer osm
        baseMaps = {
            "Base OSM": osm,
            "Bing Aerial":window.bing
        }

        layersControl = new L.Control.Layers baseMaps

        map.addControl(layersControl);
        map.addControl(new L.Control.Scale());

        if existing
            group = _.groupBy existing.grids, (grid) -> 
                grid.name[0]
            window.columns = group["A"].length
            window.rows = (_.toArray group).length

        if not existing
            map.locate({setView:true,maxZoom:16})
            window.columns = 2;
            window.rows = 2;

        backgroup = new L.LayerGroup();
        window.backgroup = backgroup
        map.addLayer(window.backgroup);
        
        modifyGroup = new L.LayerGroup();
        window.modifyGroup = modifyGroup;
        map.addLayer(window.modifyGroup)

        return map
  setRectangle:(map,helpGroup,existing) ->
        if existing  
            southWest = new L.LatLng(existing.sw.lat,existing.sw.lng)
            northEast = new L.LatLng(existing.ne.lat,existing.ne.lng)
        else
            southWest = map.containerPointToLatLng(new L.Point(640,450))
            northEast = map.containerPointToLatLng(new L.Point(280,200))

        placement = new L.LatLngBounds(southWest, northEast)

        rectangle = new L.Rectangle(placement, {
                        color: "#000000",
                        opacity: 1,
                        weight: 3,
                        fillOpacity:0
                        });
        #add the rectangle to the map
        map.addLayer rectangle

        rectangle.dragging = new L.Handler.PolyDrag rectangle
        rectangle.dragging.enable();
        rectangle.on 'move', (e) ->
            if map.hasLayer helpGroup
                map.removeLayer helpGroup
            GridServices.ResetFramer(rectangle)

        resizePoint = new L.Point(42,39);

        resize_span = '<i class="icon-fullscreen icon-large"></i>'
        resizeIcon = L.divIcon({html:resize_span,className:'resize-div-icon',iconSize:resizePoint})

        marker3 = new L.Marker(rectangle.getLatLngs()[3], {draggable : true,icon: resizeIcon});

        map.addLayer(marker3);

        window.marker3 = marker3;

        marker3.on 'drag',(event) ->

            if map.hasLayer helpGroup
                map.removeLayer helpGroup
            #inspired and modified from http://maps.forum.nu/v3/gm_rectangle_preserve_aspect_ratio.html

            new_sepoint = marker3.getLatLng();

            current_bounds = rectangle.getBounds()

            newbounds = new L.LatLngBounds(
                    current_bounds.getNorthWest(),
                    new_sepoint,
                    current_bounds.getNorthEast(),
                    current_bounds.getSouthWest()
                    )

            rectangle.setBounds(newbounds)

            NEpt = map.latLngToContainerPoint(newbounds.getNorthEast());
            SWpt = map.latLngToContainerPoint(newbounds.getSouthWest());
            delta_x = Math.abs(NEpt.x - SWpt.x);
            delta_y = Math.abs(NEpt.y - SWpt.y);
            XY_ratio = (delta_x / delta_y).toFixed(6);

            delta_y = delta_x / window.XY_ratio;
            newguy = new L.Point(NEpt.x - delta_x, NEpt.y + delta_y)
            SW = map.containerPointToLatLng(newguy);


            nextbounds = new L.LatLngBounds(
                SW,
                newbounds.getNorthEast()
            )

            rectangle.setBounds(nextbounds)

            GridServices.ResetFramer(rectangle)
      
        return rectangle
  PrepBacker:(rectangle) ->
        window.backgroup.clearLayers();
        size = map.getSize();
        maptl = new L.Point(0,0)
        maptr = new L.Point(size.x,0)
        mapbl = new L.Point(0,size.y)
        mapbr = new L.Point(size.x,size.y)

        rectbounds = rectangle.getBounds();
        tl = map.latLngToContainerPoint(rectbounds.getNorthWest());
        tr = map.latLngToContainerPoint(rectbounds.getNorthEast());
        bl = map.latLngToContainerPoint(rectbounds.getSouthWest());
        br = map.latLngToContainerPoint(rectbounds.getSouthEast());

        top_bounds = new L.LatLngBounds(map.containerPointToLatLng(maptl), map.containerPointToLatLng(new L.Point(size.x,tl.y)));
        bottom_bounds = new L.LatLngBounds(map.containerPointToLatLng(new L.Point(0,bl.y)), map.containerPointToLatLng(mapbr));
        left_bounds = new L.LatLngBounds(map.containerPointToLatLng(new L.Point(0,tl.y)), map.containerPointToLatLng(new L.Point(tl.x,br.y)));
        right_bounds = new L.LatLngBounds(map.containerPointToLatLng(new L.Point(tr.x,tr.y)), map.containerPointToLatLng(new L.Point(maptr.x,br.y)));
        shaded = {fillOpacity: 0.3,color:"#000000",weight:0}
        window.backgroup.addLayer(L.rectangle(top_bounds, shaded))
        window.backgroup.addLayer(L.rectangle(bottom_bounds, shaded))
        window.backgroup.addLayer(L.rectangle(left_bounds, shaded))
        window.backgroup.addLayer(L.rectangle(right_bounds, shaded))
  BindControls:() ->
        pagecounter = $('.leaflet-control-pagecounter')
        $("#map").on 'click',"#s_col",->
            if window.columns > 1
                GridServices.ColumnModify 'S'
        $("#map").on 'click',"#s_row",->
            if window.rows > 1
                GridServices.RowModify 'S' 
        $("#map").on 'click',"#a_col",->
            newcount = (window.columns+1)*window.rows;
            if (newcount <= 16)
                GridServices.ColumnModify('A')
            else
                $(pagecounter).popover({'placement':'left','title':'Error','trigger' : 'manual','content': "The maximum amount of allowed grids is 16."})
                $(pagecounter).popover('show');
                setTimeout () ->
                    $(pagecounter).popover('hide')
                ,2500
        $("#map").on 'click',"#a_row",->
            newcount = window.columns*(window.rows+1);
            if (newcount <= 16)
                GridServices.RowModify('A')
            else
                $(pagecounter).popover({'placement':'left','title':'Error','trigger' : 'manual','content': "The maximum amount of allowed grids is 16."}).popover('show');
                setTimeout () -> 
                    $(pagecounter).popover('hide')
                ,2500

  ResetHelp:(rowHelp,columnHelp,resizeHelp)->
        rowHelp.setLatLng window.cr_latlng
        columnHelp.setLatLng window.bc_latlng
        resizeHelp.setLatLng window.marker3.getLatLng()

  SetModifyMarkers:() ->
        window.modifyGroup.clearLayers()
        rect_dimensions = GridServices.GetRectDimensions(rectangle);
        bl = map.latLngToContainerPoint rectangle.getBounds().getSouthWest()
        tr = map.latLngToContainerPoint rectangle.getBounds().getNorthEast()
        center_right_y_pos = (rect_dimensions.h/2)+tr.y
        center_right = new L.Point(tr.x,center_right_y_pos)

        bottom_right_x_pos = (rect_dimensions.w / 2) + bl.x
        bottom_center = new L.Point(bottom_right_x_pos, bl.y)

        bc_latlng = map.containerPointToLatLng (bottom_center)
        cr_latlng = map.containerPointToLatLng (center_right);
        
        window.bc_latlng = bc_latlng
        window.cr_latlng = cr_latlng
        window.modifyGroup.addLayer new L.Marker(bc_latlng, { icon: window.rowIcon})

        window.modifyGroup.addLayer new L.Marker(cr_latlng, { icon: window.colIcon})
  GetRectDimensions:(rectangle) ->
        bounds = rectangle.getBounds()
        ne = map.latLngToContainerPoint(bounds.getNorthEast())
        sw = map.latLngToContainerPoint(bounds.getSouthWest())
        n = ne.y
        s = sw.y
        e = ne.x
        w = sw.x
        width = (e-w)
        height = (s-n)
        return {w:width,h:height}
  RowModify:(add_or_subtract) ->
        bounds = rectangle.getBounds();

        newheight = (GridServices.GetRectDimensions(rectangle).h)/window.rows
        additionPoint = new L.Point(0,newheight);
        if (add_or_subtract=='A') 
            southWest = map.containerPointToLatLng map.latLngToContainerPoint(bounds.getSouthWest()).add(additionPoint)
            window.rows = window.rows + 1;
        
        else 
            southWest = map.containerPointToLatLng(map.latLngToContainerPoint(bounds.getSouthWest()).subtract(additionPoint));
            window.rows = window.rows - 1;
        
        northEast = bounds.getNorthEast()
        new_bounds_to_set = new L.LatLngBounds(southWest, northEast);
        rectangle.setBounds(new_bounds_to_set)

        GridServices.ResetFramer(rectangle)
  ColumnModify:(add_or_subtract) ->
        bounds = rectangle.getBounds();

        newwidth = (GridServices.GetRectDimensions(rectangle).w)/window.columns
        additionPoint = new L.Point(newwidth,0);
        if (add_or_subtract=='A') 
            northEast = map.containerPointToLatLng(map.latLngToContainerPoint(bounds.getNorthEast()).add(additionPoint));
            window.columns = window.columns + 1;
        
        else 
            northEast = map.containerPointToLatLng(map.latLngToContainerPoint(bounds.getNorthEast()).subtract(additionPoint));
            window.columns = window.columns - 1;
        

        southWest = bounds.getSouthWest()
        new_bounds_to_set = new L.LatLngBounds(southWest, northEast);
        rectangle.setBounds(new_bounds_to_set)
        
        GridServices.ResetFramer(rectangle)
  PrepPayload:() ->
        prepped_array = _.map Grids.models,(grid_square) ->
            thesebounds = grid_square.get('rectangle').getBounds()
            ne = thesebounds.getNorthEast()
            sw = thesebounds.getSouthWest()
            newobj = {"ne":ne,"sw":sw,"name":grid_square.get('name')}
            return newobj          

        grouped_array = _.groupBy prepped_array,(grid) -> 
            return grid.name[0]
        new_set = []
        incrementator = 0
        for set,letter_index of grouped_array
            for grid, number_index in letter_index
                grid.index = incrementator
                grid.name = set + '' +parseInt(number_index+1);
                new_set.push grid
                incrementator++;
        return new_set