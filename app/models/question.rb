class Question < ActiveRecord::Base
  belongs_to :survey
  has_many :answers
  attr_accessible :form, :index, :label, :note

  self.include_root_in_json = false

  require_dependency 'xgeoservices'

  def retrieval_map
    #add points in here?
      if form=='fillin'
        "text"
      elsif form.start_with?('date')
        "stamp"
      else
        "number"
      end
  end

  def nice_version
    case form
      when 'fillin' 
        "Text"
      when 'number'
         "Number"
      when 'date'
         "Date"
      when 'datetime' 
         "Date+Time"
    end
  end

  def short_version
    case form
      when 'fillin' 
        "F"
      when 'number'
         "N"
      when 'date'
         "D"
      when 'datetime' 
         "DT"
    end
  end

  def symbol_retrieval_map
      if form=='fillin'
        :text
      elsif form.start_with?('date')
       :stamp
      elsif form=='number'
        :number
      else
        :points
      end
  end

  def upload_field_help(current_user)
      if form=='fillin'
        "Enter text"
      elsif form == ('date')
        if current_user.pref_us_time_format
          "Enter date in MM/DD/YYYY format"
        else
          "Enter date in DD/MM/YYYY format"
        end
      elsif form == 'datetime'
        if current_user.pref_us_time_format
          "Enter date+time in MM/DD/YYYY H:MM AM/PM format"
        else
          "Enter date+time in MM/DD/YYYY HH:MM format"
        end

      elsif form=='number'
        "Enter a number."
      else
        ""
      end
  end

  def answers_for_report(report)
      rids = report.spresults.where(:status => true)

      theanswers = self.answers.joins{spresult}.where{spresult_id.in(rids.select{id})}
      if self.form=='fillin'
        return theanswers.count(:group => "text").each_pair{|k,v|}.map{|k,v| {:text => k,:count => v}}
      elsif self.form=='geo_point' or self.form=='geo_circle' or self.form=='geo_polygon' or self.form=='geo_line'
        points = theanswers.order(:spresult_id).joins{points}.includes(:points)
        return points
      end

  end

  def choice_list
    #Not in use. Previously used for generating fillin choice lists serverside.
    Rails.cache.fetch([id,"choices"]) do
      self.answers.joins{spresult}.where{spresult.status ==  true}.select(:text).uniq.order(:text).map(&:text)
    end
  end

  def wipe_caches
    #Not needed at this time.
    #Rails.cache.delete([id,"choices"])
  end

  def result_set

    theanswers = self.answers.joins{spresult}.where{spresult.status == true}

    if self.form=='fillin'
      return theanswers.count(:group => "text").each_pair{|k,v|}.map{|k,v| {:text => k,:count => v}}
    elsif self.form=='geo_point' or self.form=='geo_circle' or self.form=='geo_polygon' or self.form=='geo_line'
      points = theanswers.order(:spresult_id).joins{points}.includes(:points)
      return points
    end

  end

  def min
    if form=='number'
      theanswers = self.answers.joins{spresult}.where{spresult.status ==  true}.minimum(:number)
    else
      theanswers = self.answers.joins{spresult}.where{spresult.status ==  true}.minimum(:stamp)
    end
  end

  def max
    if form=='number' 
      theanswers = self.answers.joins{spresult}.where{spresult.status ==  true}.maximum(:number)
    else
      theanswers = self.answers.joins{spresult}.where{spresult.status ==  true}.maximum(:stamp)
    end
  end

  def as_json(options={})
    super(:except => [:survey_id,:created_at,:updated_at])
  end


end
