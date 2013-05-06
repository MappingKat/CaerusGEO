class Report < ActiveRecord::Base
  belongs_to :survey, :touch => true
  belongs_to :user
  has_many :spresults, :dependent => :destroy
  attr_accessible :method, :status, :title

  def unfinished_answers_count
      spresults.where(:status => false).count
  end

  def unfinished_answers
    return unfinished_answers_count >= 1
  end

  def finished_answers
    return spresults.where(:status => true)
  end

  def all_entries
    return spresults.where(:status => true).order{spresult.answers.question_id}.includes(:answers => [:points])
  end

  def finished_answers_count
      spresults.count-unfinished_answers_count
  end

  def flush
    #only used for uploaded method. 
    if unfinished_answers == false
      self.status = true
      self.save
    end
  end

end


