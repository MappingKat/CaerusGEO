class Grid < ActiveRecord::Base
  belongs_to :area
  attr_accessible :index, :name
  has_one :ne, as: :location, :class_name => 'Point',:conditions => {:location_subtype => 'grid_ne'}, :dependent => :destroy
  has_one :sw, as: :location, :class_name => 'Point',:conditions => {:location_subtype => 'grid_sw'}, :dependent => :destroy


  self.include_root_in_json = false


  def ne_bounds
  	return [ne.lat,ne.lng]
  end

  def sw_bounds
  	return [sw.lat,sw.lng]
  end

  def as_json(options={})
    super(:except => [:created_at,:updated_at,:area_id,:id,:index],
      :include => {:ne => {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id,:area_id]},
        :sw => {:except => [:location_id,:location_type,:location_subtype,:created_at,:updated_at,:id,:area_id]}} ,

         )
  end
end
