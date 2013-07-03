class ReportsController < ApplicationController
  before_filter :authenticate_user!, :except => [:all_entries]

  before_filter :fetch_survey, :only =>[:create]
  before_filter :authorise_as_owner, :only =>[:create]

  before_filter :fetch_report, :except =>[:create]
  before_filter :authorise_as_report_owner, :except =>[:create,:all_entries]
  before_filter :authorise_as_hybrid, :only => [:all_entries]

  require_dependency 'xgeoservices'
  require 'csv'
  include ActionView::Helpers::TextHelper

  def update
    if @report.user == current_user
      @report.update_attributes(params[:report])
      notice = "Your survey title was updated to #{params[:report][:title]}."
      respond_to do |format|
        format.html { redirect_to edit_survey_report_path, :notice => notice }
        format.json { head :no_content }
      end
    end
  end

  # GET /reports/1/edit
  def edit
    if @report.user != current_user
      redirect_to survey_analyze_path(@report.survey)+"?rid=#{@report.id}"
    end
  end

  def destroy
    if @report.user == current_user
      @survey = @report.survey
      @report.destroy
      Rails.cache.delete("views/#{@report.survey.id}_rh")
      respond_to do |format|
        format.html { redirect_to @survey }
        format.json { head :no_content }
      end
    end
  end

  def all_entries
    @report = Report.find(params[:id])
  end

  def create 

    @survey = Survey.find(params[:survey_id])
    #Create a new report instance for this survey.
    @report = @survey.reports.new(:title => params[:title])
    @report.user = current_user
    @report.save
    no_uids=0
    no_answers = 0
    if params[:thefile]
      @report.method = "u"
      @report.status = false
      prefer_us_dates = ActiveSupport::TimeZone.us_zones.map{|z|z.name}.include?(current_user.time_zone)
      def determine_answer(question,answer,prefer_us_dates)
        #Direct lat/lng placement could happen here
        if ['geo_point','geo_circle','geo_polygon','geo_line'].include?(question.form)
          return {}
        elsif question.form == 'fillin'
          return {:text => answer}
        elsif question.form == 'number'
          return {:number => answer}
        elsif ['date','datetime'].include?(question.form)
          Time.zone = @survey.time_zone
          Chronic.time_class = Time.zone
          if prefer_us_dates
            parsed_chron = Chronic.parse(answer)
          else
            parsed_chron = Chronic.parse(answer,:endian_precedence => :little)
          end 
          return {:stamp => parsed_chron}
        end

      end

      file = IO.read(params[:thefile].tempfile.path)

      questions = @survey.actual_questions
      
      CSV.new(file, :headers => true).each do |row|
        if row[0].nil?
          #uid is missing
          no_uids = no_uids+1
          
        else  

          answers_value = true

          if row.count != questions.count
            #is a column missing?
            answers_value = false
          else
            #Is a column nil?
            row.each_with_index do |column,index|
              if index > 0
                thisquestion = questions[index]
                if column[1].nil?
                  answers_value = false
                  break
                end
              end
            end
          end

          if not answers_value
            #answer is missing
            no_answers = no_answers+1
          else
            newresult = @report.spresults.create(
              :uid => row[0],
              :status => false
            )

            #make unanswered for map question.
            newone = newresult.answers.new()
            newone.question = questions[0]
            newone.save

            row.each_with_index do |column,index|
              if index > 0
                thisquestion = questions[index]
                finalized_answer = determine_answer(thisquestion,column[1],prefer_us_dates)

                newone = newresult.answers.new(finalized_answer)
                newone.question = thisquestion
                newone.save
              end
            end

          end

        end
      end
    else
      @report.method = "m"
      @report.status = true #manual reports by published by default..they are inherently done.
    end
    @report.save
    Rails.cache.delete("views/#{@report.survey.id}_rh")

    if no_uids > 0 or no_answers > 0
      errorstring = String.new
      if no_uids > 0
        errorstring << "#{pluralize(no_uids,'entry')} bypassed because of missing ID. "
      end
      if no_answers > 0
        errorstring << "#{pluralize(no_answers,'entry')} bypassed because of missing answers."
      end
    end


    if @report.method == 'u' 
      if @report.spresults.count == 0
        errorstring = defined? errorstring ? errorstring : String.new
        errorstring.prepend('There were no valid entries in this upload.Please correct your source CSV file.')
        redirect_to error_page_path, :alert => errorstring
      else
        if !errorstring.nil?
          errorstring << "You uploaded #{pluralize(@report.spresults.count,'entry')} successfully."
          redirect_to edit_survey_report_path(@survey,@report), :alert => errorstring
        else 
          redirect_to edit_survey_report_path(@survey,@report), :notice => "You uploaded #{pluralize(@report.spresults.count,'entry')} successfully."
        end
      end
    else
      redirect_to edit_survey_report_path(@survey,@report)
    end
  end

  def export_results_geojson
    @report = Report.find(params[:id])
    filename ="#{@report.survey.slugify_title}_#{@report.title}_geojson"
    answer_map = @report.survey.answer_map
    geom_type = @report.survey.geojson_type
    features = @report.all_entries.map do |spresult|
      XGEOServices.ProduceGeoJSONForSpResult(spresult,answer_map,geom_type)
    end

    geojson_data = { :type => "FeatureCollection",
    :features => features
    } 

    send_data geojson_data.to_json,
      :type => 'application/json; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.json"

  end

  def export_csv
    @report = Report.find(params[:id])
    filename ="#{@report.survey.slugify_title}_#{@report.title}_template"
    csv_data = CSV.generate({:force_quotes => true}) do |csv|
    answer_map = @report.survey.answer_map
  
    csv << [@report.survey.title]

    template_array = []
    addons = @report.survey.actual_questions.each_with_index do |question,index|
      template_array << "Q"+(index+1).to_s
    end

    csv << template_array

    @report.spresults.order(:id).each do |c| 
      csv << c.to_csv(answer_map)
    end

    end 
    send_data csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.csv"

  end

  private

  def fetch_survey
    @survey = Survey.find(params[:survey_id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, this survey with ID #{params[:id]} could't be found."
            render :template => "home/error", :status => 404
          }
      end 
  end
  

  def authorise_as_owner
     unless @survey.user == current_user or @survey.collaborators.where(:email => current_user.email).exists?
        #You don't belong here. Go away.
        respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, you can't view this survey's reports."
            render :template => "home/error", :status => 401
          }
        end 
     end
  end

  def fetch_report
    @report = Report.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, this report with ID #{params[:id]} could't be found."
            render :template => "home/error", :status => 404
          }
      end 
  end

  def authorise_as_report_owner
     unless @report.user == current_user or @report.survey.collaborators.where(:email => current_user.email).exists?
        #You don't belong here. Go away.
        respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, you can't view this report."
            render :template => "home/error", :status => 401
          }
        end 
     end
  end

  def authorise_as_hybrid
     unless @report.survey.public or (@report.survey.user == current_user or @report.survey.collaborators.where(:email => current_user.email).exists?)
        render :text => "Forbidden", :status => 401
     end
  end


end
