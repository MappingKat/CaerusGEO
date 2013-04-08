json.layout "A4 portrait"
json.title "A simple example"
json.outputFilename "#{survey.slugify_title}_atlas"
json.srs "EPSG:900913"
json.dpi 254
json.units "m" 
json.layers survey.produceVectorLayersforPDF(true)
json.pages survey.producePagesForPDF(true)