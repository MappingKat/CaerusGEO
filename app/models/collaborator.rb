class Collaborator < ActiveRecord::Base
    after_create :inform

  belongs_to :survey
  attr_accessible :email

  before_save do |collaborator|
    collaborator.email.downcase!
  end

  validates  :email, :survey, :presence => true

  self.include_root_in_json = false


  def inform

    user = User.find_for_authentication(:email => self.email)

    @message = Message.new      

    if user.nil?
      #send welcome email
      @message.name = ""
      @message.email = self.email

      @message.subject = "#{self.survey.user.name} gave you access to #{self.survey.title}"

      @message.body = "Since you appear to be a new user, you will be instructed on account registration upon first access."
    else
      @message.name = user.name
      @message.email = user.email

      @message.subject = "#{self.survey.user.name} gave you access to #{self.survey.title}"

      @message.body = ""
    end

    NotificationsMailer.new_survey_access(@message,self.survey).deliver



  end

  def existing
    user = User.find_for_authentication(:email => self.email)
    if user.nil?
      return nil
    else
      return user.name
    end
  end 

  def fullname
  user = User.find_for_authentication(:email => self.email)
    if user.nil?
      return self.email
    else
      return "#{self.email} (#{user.name})"
    end
  end

  validates_uniqueness_of :email, :scope => [:survey_id]

  def as_json(options={})
    super(:except => [:created_at,:updated_at,:_id],
          :methods => [:existing])
  end

end
