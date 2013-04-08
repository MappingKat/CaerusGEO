class OpenController < ApplicationController
  require_dependency 'xgeoservices'

  before_filter :authenticate_user!
  before_filter :fetch_survey, :except =>[:create]
  before_filter :authorise_as_owner, :except =>[:create]
  before_filter :ensure_editable

  include Wicked::Wizard
  steps :info,:type,:add_questions,:locate,:preview

  def show
    if cookies[:base] and cookies[:base_for] == params[:survey_id]
      flash.now[:notice] =  "The survey type and questions from <b>#{cookies[:base]}</b> have been replicated into this new survey.You will see them in Steps 2 and 3.<br>Please proceed through the creation process to customize as you see fit. "
    end  
  	@survey = Survey.find(params[:survey_id])
    render_wizard 
  end

  def finish_wizard_path
    cookies.delete(:base)
    cookies.delete(:base_for)
  	survey_path(@survey)+"?firstview"
  end

  def update
  	@survey = Survey.find(params[:survey_id])
    case step

      when :type
        if @survey.questions.where(:index => 0).exists?
          question = @survey.questions.where(:index => 0).update_all :form => params[:entity_type]
        else
          newquestion = @survey.questions.new(
            :label => "Geo Response",
            :index => 0,
            :form => params[:entity_type]
          )
        end
      when :add_questions
        questions = params['questions']

        if @survey.questions.count > 1
          #destroy any existing geo point questions.
          @survey.questions.order(:index).offset(1).destroy_all
        end
        questions.each do |question|

          actual_index = question['index'].to_i
          #because we added in the builtin before..
          actual_index+=1
          
          newquestion = @survey.questions.create(
            :label => question['label'],
            :index => actual_index,
            :form => question['form'],
            :note => question['note'],
          )

        end
      when :locate
        if @survey.area
          @survey.area.destroy
          @survey.save
        end
        thisarea = Area.new
        thisarea.save
        @survey.area = thisarea
        @survey.area.save
        @survey.save

        thisarea.build_ne(params[:ne_bounds])
        thisarea.build_sw(params[:sw_bounds])

        thisarea.save
       
        thumbnail = XGEOServices.ProduceThumbnail(params[:map_center][:lat],params[:map_center][:lng],params[:zoom])
        map_center = "#{params[:map_center][:lat].to_f},#{params[:map_center][:lng].to_f}"
        search = Geocoder.search(map_center)[0]
        @survey.area.city = search ? search.city : "N/A"
        @survey.area.country = search ? search.country : "N/A"
        @survey.area.thumbnail = thumbnail
        @survey.area.save
        @survey.save

        grids = params[:grids]

        #Delete all existing grids on this survey first.
        #Why do we do this?In case they decide to "go back" in the wizard, 
        #and redo their grid arrangement.
        if !@survey.area.grids.empty?
          @survey.area.grids.destroy
        end

        #Loop through our grids, and save them.
        grids.each do |grid| 
          newgrid = thisarea.grids.build(
            :name => grid['name'],
            :index => grid['index']
            )
          newgrid.build_ne(grid['ne'])
          newgrid.build_sw(grid['sw'])
        end
        @survey.area.save

      else
        @survey.update_attributes(params[:survey])
    end

    if request.xhr?
      render :text => "Done", :status => 200
    else
      render_wizard  @survey
    end
  end

private

  def fetch_survey
    @survey = Survey.find(params[:survey_id])
    rescue ActiveRecord::RecordNotFound
      #there is no such post
      render :text => "Not Found", :status => 404
      return false
  end

  def authorise_as_owner
     unless @survey.user == current_user
        #You don't belong here. Go away.
        render :text => "Forbidden", :status => 401
     end
  end

  def ensure_editable
    unless @survey.status == false or params[:id] == 'finish'
      render :text => "Survey already published.", :status => 400
    end
  end

end
