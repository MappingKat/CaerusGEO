class Area < ActiveRecord::Base
  belongs_to :survey
  attr_accessible :city, :country, :thumbnail
  has_one :ne, as: :location, :class_name => 'Point',:conditions => {:location_subtype => 'area_ne'}, :dependent => :destroy
  has_one :sw, as: :location, :class_name => 'Point',:conditions => {:location_subtype => 'area_sw'}, :dependent => :destroy

  has_many :grids, :dependent => :destroy
  self.include_root_in_json = false
  def ne_bounds
    return [ne.lat,ne.lng]
  end

  def sw_bounds
    return [sw.lat,sw.lng]
  end

  def bounds
    {:ne_bounds => ne_bounds,:sw_bounds => sw_bounds}
  end

  def as_json(options={})
    super(:except => [:created_at,:updated_at,:_id,:area_id], 
          :include => [:ne,:sw,:grids]
         )
  end
end
