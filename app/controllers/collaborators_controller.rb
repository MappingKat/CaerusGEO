class CollaboratorsController < ApplicationController
  respond_to :json
  before_filter :authenticate_user!
  before_filter :fetch_survey
  before_filter :fetch_collaborator, :only => [:destroy]
  before_filter :authorise_as_owner
  before_filter :authorise_as_part_of_survey, :only => [:destroy]

  
  def index
  	@survey = Survey.find(params[:survey_id])
    respond_with @survey.collaborators
  end
  
  def create
  	@survey = Survey.find(params[:survey_id])
  	@collaborator = @survey.collaborators.create(:email => params[:email])
    respond_with(@collaborator, :location => "")
  end
  
  def destroy
    respond_with Collaborator.destroy(params[:id])
  end

  private

  def fetch_survey
    @survey = Survey.find(params[:survey_id])
    rescue ActiveRecord::RecordNotFound
      render :text => "Survey Not Found", :status => 404
  end

  def fetch_collaborator
    @collaborator = Collaborator.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => "Collaborator Not Found", :status => 404
  end
  

  def authorise_as_owner
     unless @survey.user == current_user
        render :text => "Forbidden.This survey is not yours.", :status => 403
     end
  end

  def authorise_as_part_of_survey
     unless @collaborator.survey == @survey
        render :text => "Invalid input.This collaborator is not part of this survey.", :status => 401
     end
  end

end

