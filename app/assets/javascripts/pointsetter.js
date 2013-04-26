L.Control.Pointsetter = L.Control.extend({
  options: {
    position: 'topleft', //Should match Draw's position.
    entity_name: null
  },

  onAdd: function (map) {
    var className = 'leaflet-control-pointsetter',
        container = L.DomUtil.create('div', className);

    this._commitButton = this._createButton(
            this.options.entity_name, '',  container, this._saveCurrent,  this);
    return container;
  },

  _saveCurrent: function (e) {
    this._commitButton.innerHTML = 'Saving';
    var control = this;
    $('.leaflet-control-pointsetter').popover('hide');
    EntryServices.LeaveResult(function() {
      $(".leaflet-control-pointsetter").hide('fast');
      $("#ready").hide();
      control._commitButton.innerHTML = control.options.entity_name;
    });
  },

  _createButton: function (html, className, container, fn, context) {
    var link = L.DomUtil.create('a', className, container);
    link.innerHTML = html;
    link.href = '#';

    L.DomEvent
        .on(link, 'click', L.DomEvent.stopPropagation)
        .on(link, 'mousedown', L.DomEvent.stopPropagation)
        .on(link, 'dblclick', L.DomEvent.stopPropagation)
        .on(link, 'click', L.DomEvent.preventDefault)
        .on(link, 'click', fn, context);

    return link;
  }

});