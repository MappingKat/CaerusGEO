    var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var Grid = Backbone.Model.extend({
      defaults: {
        rectangle:null
      }
    });

    var GridCollection = Backbone.Collection.extend({
        model: Grid
    });

    var Grids = new GridCollection();

    function DrawLabel(pos,content,group) {
      var marker = new L.Marker.Text(pos, content);
      group.addLayer(marker);
    }

    function squareName(letter, index){
      return alphabet.charAt(letter)+''+parseInt(index+1);
    }

    //Grid has been defined.We draw from database provided Grid model.
    function DrawFinalizedGrid(map,group,grid_json,grid_collection) {
        group.clearLayers();
        _.each(grid_json,function(grid) { 

          var southWest = new L.LatLng(grid.sw.lat,grid.sw.lng),
              northEast = new L.LatLng(grid.ne.lat,grid.ne.lng),
              bounds = new L.LatLngBounds(southWest, northEast);

              var corners = [
                bounds.getNorthEast(),
                bounds.getNorthWest(),
                bounds.getSouthWest(),
                bounds.getSouthEast()
              ];
              var gridSquare = new L.Polygon(corners, { color:'#000', weight: 1, fill: true, fillColor: "#000", fillOpacity: 0.2, opacity: 0.4 });
              group.addLayer(gridSquare);

              var newrectangle = new Grid({'name' : grid.name,'rectangle' : gridSquare,'index':grid.index});
              grid_collection.add([newrectangle]);
              DrawLabel(corners[1],grid.name,group);
          });
        map.addLayer(group);
    }

    //This draws an example grid for locate pages. We draw according to Viewport of map.
    function DrawGrid(bounds,group,grid_collection,columns,rows) {
        //Wipe the existing one. We may have one.
        grid_collection.reset(); 
        group.clearLayers();

        bigbounds = bounds

        var gridN = bigbounds.getNorthEast().lat,
            gridS = bigbounds.getSouthWest().lat,
            gridE = bigbounds.getNorthEast().lng,
            gridW = bigbounds.getSouthWest().lng;

        var gridColumns = columns,
            gridRows = rows;

        /* prepare to draw and store grid data */
        var gridRowHeight = (gridN - gridS) / gridRows,
            gridColumnWidth = (gridE - gridW) / gridColumns;

        for(var i=0; i<gridColumns; i++){
          for(var j=0; j<gridRows; j++){
              var corners = [
                new L.LatLng( gridN - j * gridRowHeight, gridW + i * gridColumnWidth ),
                new L.LatLng( gridN - j * gridRowHeight, gridW + (i+1) * gridColumnWidth ),
                new L.LatLng( gridN - (j+1) * gridRowHeight, gridW + (i+1) * gridColumnWidth ),
                new L.LatLng( gridN - (j+1) * gridRowHeight, gridW + i * gridColumnWidth )
              ];
              var thisname = squareName(j, i);
              var gridSquare = new L.Polygon(corners, 
                { 
                  color:'#000', 
                  weight: 1, 
                  fill: false, 
                  fillColor: "#000", 
                  fillOpacity: 0.2, 
                  opacity: 0.4,
                  'name' : thisname
                }
              );
              group.addLayer(gridSquare);

              var newrectangle = new Grid({'name' : thisname,'rectangle' : gridSquare,'index':grid_collection.length});
              grid_collection.add([newrectangle]);
              DrawLabel(corners[0],newrectangle.get('name'),group);
          }
        }
        window.map.addLayer(group);
    }
