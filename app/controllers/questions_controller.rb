class QuestionsController < ApplicationController
  before_filter :authenticate_user!,:except => [:answer_breakdown]
  before_filter :fetch_survey
  before_filter :verify_proper_survey
  before_filter :authorise_as_owner, :except =>[:answer_breakdown]
  before_filter :authorise_as_hybrid, :only =>[:answer_breakdown]

  #def show
  #	@survey = Survey.find(params[:survey_id])
  #	@spresults = @survey.all_spresults
  #	@question = Question.find(params[:id])
  #end

  #def answer_breakdown
  #	@question = Question.find(params[:id])
  #	set = @question.result_set
  #	
  #
  #	formatted = set.map{|ans_set| {:letter => ans_set[:text],:frequency => ans_set[:count] }}
  #  formatted.sort_by!{|thing| thing[:letter]}
  #	respond_to do |format|
  #    format.json { render :json => formatted }
  # end  
  #end

  private

  def verify_proper_survey
    @question = Question.find(params[:id])
    unless @question.survey_id == @survey.id
      render :text => "This Question doesn't belong to this survey.", :status => 401
    end
  end

  def fetch_survey
    @survey = Survey.find(params[:survey_id])
    rescue ActiveRecord::RecordNotFound
        #there is no such post
      render :text => "Not Found", :status => 404
       return false
  end
  

  def authorise_as_owner
     unless @survey.user == current_user or @survey.collaborators.where(:email => current_user.email).exists?
        #You don't belong here. Go away.
        render :text => "Forbidden", :status => 401
     end
  end

  def authorise_as_hybrid
     if not @survey.public
        if not @survey.user == current_user or @survey.collaborators.where(:email => current_user.email).exists?
        #You don't belong here. Go away.
          render :text => "Forbidden", :status => 401
        end
     end
  end

end
