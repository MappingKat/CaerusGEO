class Point < ActiveRecord::Base
  attr_accessible :lat, :lng, :location_type,:location_subtype
  belongs_to :location, polymorphic: true
  self.include_root_in_json = false

  def loc
    return [lat,lng]
  end

  def as_json(options={})
    super(:except => [:id,:created_at,:updated_at,:location_type,:location_subtype,:location_id])
  end
end
