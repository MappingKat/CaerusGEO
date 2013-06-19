L.Control.Pointsetter = L.Control.extend({
  options: {
    position: 'topleft', //Should match Draw's position.
    entity_name: null
  },

  onAdd: function (map) {
    var className = 'leaflet-control-pointsetter',
        container = L.DomUtil.create('div', className);

    this._commitButton = this._createButton(
            this.options.entity_name, 'pointsetter-commit',  container);
    return container;
  },

  _createButton: function (html, className, container, fn, context) {
    var link = L.DomUtil.create('a', className, container);
    link.innerHTML = html;
    link.href = '#';
    return link;
  }

});