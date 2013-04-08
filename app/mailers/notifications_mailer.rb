class NotificationsMailer < ActionMailer::Base

  
  default :from => "support@caerusgeo.com"
  default :to => "support@caerusgeo.com"

  def new_message(message)
    @message = message
    mail(:subject => "[CaerusGeo] #{message.subject}")
  end

  def new_survey_access(message,survey)
    @message = message
    @survey = survey
    mail(:subject => "[CaerusGeo] #{message.subject}", :to => message.email)
  end



end