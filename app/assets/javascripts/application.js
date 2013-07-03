// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.sortable
//= require jquery.ui.widget
//= require bootstrap
//= require underscore
//= require backbone
//= require drawgrid
//= require aerial
//= require markertext
//= require select2
//= require_tree .
var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
var osmAttrib='Map data © openstreetmap contributors';

_.templateSettings = {
    interpolate: /\<\@\=(.+?)\@\>/gim,
    evaluate: /\<\@(.+?)\@\>/gim
};

$(document).ready(function() {
  var bing = new L.BingLayer(window.bing_api_key);
  var green_icon = new L.Icon({
      iconUrl: '//s3.amazonaws.com/co_m_assets/marker-icon-green.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [0, -23],
      shadowUrl: '//s3.amazonaws.com/co_m_assets/marker-shadow.png',
      shadowSize: [41,41],
      shadowAnchor: [13, 41]
  });
  window.bing = bing;
  window.green_icon = green_icon;
});

  var sorted_path = {
    'fillColor':'#6BB130',
    'fillOpacity':0.8,
    'color': '#6BB130'
  }

Question = Backbone.Model.extend({});

var QuestionCollection = Backbone.Collection.extend({
      model: Question
});

function validateEmail(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}

function thisCentroid(entity) {
  //http://stackoverflow.com/questions/9692448/how-can-you-find-the-centroid-of-a-concave-irregular-polygon-in-javascript
  var pts = _.map(entity.getLatLngs(),function(point) {
          return {x:point.lng,y:point.lat}
  });

  var twicearea=0,
       x=0, y=0,
       nPts = pts.length,
       p1, p2, f;
   for (var i=0, j=nPts-1 ;i<nPts;j=i++) {
      p1=pts[i]; p2=pts[j];
      twicearea+=p1.x*p2.y;
      twicearea-=p1.y*p2.x;
      f=p1.x*p2.y-p2.x*p1.y;
      x+=(p1.x+p2.x)*f;
      y+=(p1.y+p2.y)*f;
   }
   f=twicearea*3;
   var center =  new L.LatLng(y/f,x/f)
   return center
}