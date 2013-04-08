module XGEOServices
	require 'mercator'
	def self.ProduceThumbnail(lat,lng,zoom)

		 adjusted_zoom = zoom-1

	      center_in_m = Mercator.LatLonToMeters(lat,lng)
	      centertile = Mercator.MetersToTile(center_in_m[0],center_in_m[1],adjusted_zoom)
	      googletile = Mercator.GoogleTile(centertile[0],centertile[1],adjusted_zoom)

	      thumbnail = "http://b.tile.openstreetmap.org/%s/%s/%s.png" % [adjusted_zoom,googletile[0],googletile[1]]


		return thumbnail
	end

	def self.GetAreaCentroidInM(area_points)
		newformat = XGEOServices.transformLUAreatoGeoJson(area_points)
		centroid = XGEOServices.GetCentroidOfPolygon(newformat)
		return Mercator.LatLonToMeters(centroid[1],centroid[0])
	end

	def self.transformLUAreatoGeoJson(points)
		points.map do |point| 
			[point.loc[1],point.loc[0]]
		end
	end

	def self.GetCentroidOfPolygon(coordinates)
		#modified from https://code.google.com/p/tokland/source/browse/trunk/centroid/center.rb
	    consecutive_pairs = (coordinates + [coordinates.first]).each_cons(2)
	    area = (1.0/2) * consecutive_pairs.map do |(x0, y0), (x1, y1)|
	      (x0*y1) - (x1*y0)
	    end.inject(:+)

	    consecutive_pairs.map do |(x0, y0), (x1, y1)|
	      cross = (x0*y1 - x1*y0)
	      [(x0+x1) * cross, (y0+y1) * cross]
	    end.transpose.map { |cs| cs.inject(:+) / (6*area) }

	end

	def self.GetBoxInM(survey)
		in_meters = Mercator.LatLonToMeters(survey.area.sw_bounds[0],survey.area.ne_bounds[1]) + Mercator.LatLonToMeters(survey.area.ne_bounds[0],survey.area.sw_bounds[1])
		return [in_meters[2],in_meters[1],in_meters[0],in_meters[3]]
	end

	def self.GetBoxInM_frombounds(ne_bounds,sw_bounds)
		in_meters = Mercator.LatLonToMeters(sw_bounds[0],ne_bounds[1]) + Mercator.LatLonToMeters(ne_bounds[0],sw_bounds[1])
		return [in_meters[2],in_meters[1],in_meters[0],in_meters[3]]
	end

	def self.GetGridInM(grid)
		#Clockwise fashion from top right.
		square = [
			Mercator.LatLonToMeters(grid.ne_bounds[0],grid.ne_bounds[1]),
			Mercator.LatLonToMeters(grid.ne_bounds[0],grid.sw_bounds[1]),
			Mercator.LatLonToMeters(grid.sw_bounds[0],grid.sw_bounds[1]),
			Mercator.LatLonToMeters(grid.sw_bounds[0],grid.ne_bounds[1]),
			Mercator.LatLonToMeters(grid.ne_bounds[0],grid.ne_bounds[1])
		]

		return square
	end

	def self.GetFeatFromPointsInM(points)
		#Clockwise fashion from top right.
		in_ll = points.map do |point| [point[:lat],point[:lng]] end
  		in_ll << [points.first[:lat],points.first[:lng]]

		in_m = in_ll.map do |point| Mercator.LatLonToMeters(point[0],point[1]) end
		return in_m
	end

	def self.GetLineString(points)
		#Clockwise fashion from top right.
		in_ll = points.map do |point| [point[:lat],point[:lng]] end
		in_m = in_ll.map do |point| Mercator.LatLonToMeters(point[0],point[1]) end
		return in_m
	end

	def self.GetPolygonAreaInM(concession)
		#Clockwise fashion from top right.
		in_ll = concession.points.map do |point| [point.loc[0],point.loc[1]] end
  		in_ll << [concession.points.first.loc[0],concession.points.first.loc[1]]

		in_m = in_ll.map do |point| Mercator.LatLonToMeters(point[0],point[1]) end
		return in_m
	end

	def self.GetPointInM(point)
		return Mercator.LatLonToMeters(point[0],point[1])
	end

	def self.GetLabelBox(grid)
		#Clockwise fashion from top left.
		#dont we need abs here too?
		x_range = (grid.ne_bounds[0] - grid.sw_bounds[0])
		y_range = (grid.sw_bounds[1] - grid.ne_bounds[1])
		x_offset = (x_range*0.07)
		y_offset = (y_range*0.06)


		square = [
			Mercator.LatLonToMeters(grid.ne_bounds[0],grid.ne_bounds[1]),
			Mercator.LatLonToMeters((grid.ne_bounds[0]-x_offset),grid.ne_bounds[1]),
			Mercator.LatLonToMeters((grid.ne_bounds[0]-x_offset),(grid.ne_bounds[1]+y_offset)),
			Mercator.LatLonToMeters(grid.ne_bounds[0],(grid.ne_bounds[1]+y_offset)),
			Mercator.LatLonToMeters(grid.ne_bounds[0],grid.ne_bounds[1])
		]

		return square
	end

	def self.ProduceGridPages(survey)
		grid_pages = []
			
		survey.area.grids.includes(:ne,:sw).order(:name).each do |grid|

			in_meters =  Mercator.LatLonToMeters((grid.sw_bounds[0]),(grid.ne_bounds[1])) + Mercator.LatLonToMeters((grid.ne_bounds[0]),(grid.sw_bounds[1]))

			obj = {
				:index => grid.index,
				:label => grid.name,
				:bbox => [in_meters[2],in_meters[1],in_meters[0],in_meters[3]]
			}

			grid_pages << obj
		end

		return grid_pages
	end

	def self.ProduceGeoJSONForSpResult(spresult,answer_map,geom_type)
		obj = {
    		:type => "Feature",
    		:geometry => {
        		:type => geom_type,
        		:coordinates => nil
        	},
        	:properties => Hash.new
        	}


	    spresult.answers.order(:question_id).each_with_index do |thisanswer,index|
	      if index==0
	      	case geom_type
	      		when 'Point'
	      			point = thisanswer.points.first
	      			finished_array = [point.lng,point.lat]
	      		when 'LineString'
	      			finished_array = thisanswer.points.map{|point| [point.lng,point.lat] }
	      		when 'Polygon'
	      			built_array = thisanswer.points.map{|point| [point.lng,point.lat] }
	      			built_array << 	built_array[0]
	      			finished_array = [built_array]
	      	end
	        		
	        obj[:geometry][:coordinates] = finished_array
	      else
	      	found = answer_map.at(index)
	      	realname = found[:label]
        	obj[:properties][realname] =  thisanswer.send(found[:answer])
	      end
	    end

	    return obj

	end
end
