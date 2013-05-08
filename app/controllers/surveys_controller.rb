class SurveysController < ApplicationController
  require 'uri'
  require 'csv'
  require_dependency 'xgeoservices'
  before_filter :authenticate_user!, :except =>[:public,:all_entries]
  before_filter :fetch_survey, :except =>[:new]
  before_filter :authorise_as_viewable, :except =>[:new,:all_entries,:public,:update, :destroy]
  before_filter :authorise_as_hybrid, :only => [:public,:all_entries]
  before_filter :authorise_as_owner, :only => [:update,:destroy]

  def all_entries
    @survey = Survey.find(params[:id])
  end

  def print_atlas
    @survey = Survey.find(params[:id])
    redirect_to @survey.getAtlasURL
  end  

  def print_wallmap
    @survey = Survey.find(params[:id])
    redirect_to @survey.getWallmapURL
  end 

  def export_results_csv
    @survey = Survey.find(params[:id])
    filename ="#{@survey.slugify_title}_results"

    answer_map = @survey.answer_map

    csv_data = CSV.generate do |csv|
      csv << ["#{@survey.title},#{@survey.area.city},#{@survey.area.country}"]
      main_header_row = [@survey.geo_type]
      @survey.field_questions.each do |question|
        main_header_row << question.label
      end
      csv << main_header_row
      @survey.reports.each do |report|
        report.finished_answers.each do |spresult| 
          csv << spresult.to_csv(answer_map)
        end
      end 
    end 
    send_data csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.csv"

  end

  def export_csv_template
    @survey = Survey.find(params[:id])
    filename ="#{@survey.slugify_title}_template"
    csv_data = CSV.generate({:force_quotes => true}) do |csv|
      
      template_array = ["Entry ID"]
      
      addons = @survey.actual_questions.each_with_index do |question,index|
        if index > 0
          template_array << "Q#{index.to_s} - #{question.label} (#{question.upload_field_help(current_user)})"
        end
      end

      csv << template_array
    end 
    send_data csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.csv"

  end

  def export_results_geojson
    @survey = Survey.find(params[:id])
    filename ="#{@survey.slugify_title}_geojson"
    answer_map = @survey.answer_map
    geom_type = @survey.geojson_type
    features = @survey.all_entries.map do |spresult|
      XGEOServices.ProduceGeoJSONForSpResult(spresult,answer_map,geom_type)
    end

    geojson_data = { :type => "FeatureCollection",
    :features => features
    } 

    send_data geojson_data.to_json,
      :type => 'application/json; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.json"

  end

  def export_blank_results
    @survey = Survey.find(params[:id])

    prawnto :prawn => { :page_layout => :landscape, :page_size => "A4"}

    respond_to do |format|
      format.pdf do
         prawnto filename: "#{@survey.slugify_title}_worksheet.pdf", :inline => false
         render "blank_results" 
      end
    end   
  end

  def show
    @survey = Survey.includes(:area => [{:grids => [:ne,:sw]}]).find(params[:id])
    respond_to do |format|
      format.html
    end   
  end

  def analyze
    @survey = Survey.includes(:area => [{:grids => [:ne,:sw]}]).find(params[:id])
    respond_to do |format|
      format.html
    end   
  end

  def update
    @survey = Survey.find(params[:id])
    @survey.update_attributes(params[:survey])
    redirect_to (url_for(@survey)+"#m"), :notice => "Your survey was updated."
  end

  def public
    @survey = Survey.includes(:area => [{:grids => [:ne,:sw]}]).find(params[:id])
    respond_to do |format|
      format.html do
        render :template => "surveys/analyze"
      end
    end   
  end

  def destroy
    @survey = Survey.find(params[:id])
    @survey.destroy
    redirect_to user_path(current_user), :alert => "Your survey was deleted."
  end

	def new
    #Make a new survey for a user.
		@survey = current_user.surveys.create(:time_zone => current_user.time_zone)
    if params[:base]
      @base = Survey.find(params[:base])
      @base.questions.each do |question|
        newquestion = question.dup
        newquestion.survey = @survey
        newquestion.save
      end
      cookies[:base] = @base.title
      cookies[:base_for] = @survey.id
      @survey.base = @base.id
      @survey.save
    end
    redirect_to :controller => :open, :survey_id => @survey
	end

private

  def fetch_survey
    @survey = Survey.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, this survey with ID #{params[:id]} could't be found."
            render :template => "home/error", :status => 404
          }
      end 
  end
  

  def authorise_as_viewable
     unless @survey.user == current_user or @survey.collaborators.where(:email => current_user.email).exists?
        #You don't belong here. Go away.
        respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, you can't view this survey."
            render :template => "home/error", :status => 401
          }
        end 
     end
  end

  def authorise_as_owner
     unless @survey.user == current_user
        #You don't belong here. Go away.
        respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, you can't edit this survey."
            render :template => "home/error", :status => 401
          }
        end 
     end
  end

  def authorise_as_hybrid
     unless @survey.public or (current_user and (@survey.user == current_user or @survey.collaborators.where(:email => current_user.email).exists?))
        #You don't belong here. Go away.
        respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, this survey isn't public."
            render :template => "home/error", :status => 401
          }
      end 
     end
  end


end
