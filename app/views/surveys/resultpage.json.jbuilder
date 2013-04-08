json.layout "Open portrait"
json.title "A simple example"
json.srs "EPSG:900913"
json.dpi 254
json.units "m" 
json.layers @survey.produceVectorLayersforResultPDF(@entities)
json.pages @survey.producePagesForPDF(true)[0...1]