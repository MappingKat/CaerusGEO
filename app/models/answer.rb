class Answer < ActiveRecord::Base
  belongs_to :spresult
  belongs_to :question
  has_many :points, as: :location
  attr_accessible :text, :number, :stamp
  accepts_nested_attributes_for :points
  self.include_root_in_json = false

  validates :spresult, :question, :presence => true


  def content
    if self.question.form.start_with?('geo')
      if question.form == 'geo_point'
        return points.first
      else
        return points
      end
    else
      if question.form == 'fillin'
        return text
      elsif question.form == 'number'
        return number
      else
        return stamp
      end 
    end
  end

  def as_json(options={})
      super(:except => [:created_at,:updated_at,:id],
        :include => {
                    :points => {:except => [:created_at,:updated_at,:location_type,:location_subtype,:location_id]}})
  end
end
