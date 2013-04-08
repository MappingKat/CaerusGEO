L.Control.Pointsetter = L.Control.extend({
  options: {
    position: 'topleft'
  },

  initialize: function (options) {
        this._config = {};
        this.setConfig(options);
    },

  setConfig: function (options) {
      this._config = {
          'entity_name': options.entity_name
      };
  },

  onAdd: function (map) {
    var className = 'leaflet-control-pointsetter',
        container = L.DomUtil.create('div', className);

    this._map = map;

 

    this._commitButton = this._createButton(
            this._config.entity_name, this._config.entity_name,  className + '-in',  container, this._saveCurrent,  this);

    return container;
  },

  onRemove: function (map) {
   
  },

  _saveCurrent: function (e) {
    $(".leaflet-control-pointsetter a").text('Saving');
    var control = this;
    $('.leaflet-control-pointsetter').popover('hide');
    var config = this._config;
    EntryServices.LeaveResult(function() {
      $(".leaflet-control-pointsetter").hide('fast');
      $("#ready").hide();
      $(".leaflet-control-pointsetter a").text(config.entity_name);
    });
    
  },

  _createButton: function (html, title, className, container, fn, context) {
    var link = L.DomUtil.create('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    link.title = title;

    L.DomEvent
        .on(link, 'click', L.DomEvent.stopPropagation)
        .on(link, 'mousedown', L.DomEvent.stopPropagation)
        .on(link, 'dblclick', L.DomEvent.stopPropagation)
        .on(link, 'click', L.DomEvent.preventDefault)
        .on(link, 'click', fn, context);

    return link;
  }

});