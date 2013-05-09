class Spresult < ActiveRecord::Base
  belongs_to :report, :touch => true
  attr_accessible :uid, :status
  has_many :answers, :dependent => :destroy

  validates :report, :presence => true

  self.include_root_in_json = false

  after_create(:on => :create) do
    self.wipe_caches
  end

  after_save(:on => :update) do
    self.wipe_caches
  end

  def wipe_caches
    Rails.cache.delete("views/#{report.survey.id}_rh")
  end


  def to_csv(answer_map)
      
    answer_array = []

    self.answers.order(:question_id).each_with_index do |answer,index|
      if index == 0
        arrays = answer.points.map{|point| point.loc }
        arrays.join(',')
        answer_array << arrays
      else
        answer_array << answer.send(answer_map.at(index)[:answer])
      end
    end

    return answer_array

  end


  def as_json(options={})
    super(:except => [:created_at,:updated_at,:report_id], 
          :include => {:answers =>  { :include => {:points => {:except => [:id,:created_at,:updated_at,:location_type,:location_subtype,:location_id]}},
                                      :except => [:spresult_id,:created_at,:updated_at] 
                                    } 
                      }
         )
  end
end
