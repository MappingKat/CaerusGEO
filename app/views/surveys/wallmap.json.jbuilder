json.layout "A0 portrait"
json.title "A simple example"
json.outputFilename "#{survey.slugify_title}_wallmap"
json.srs "EPSG:900913"
json.dpi 254
json.units "m" 
json.layers survey.produceVectorLayersforPDF(false)
json.pages survey.producePagesForPDF(false)