class SpresultsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :fetch_report
  before_filter :fetch_spresult, :only => [:update, :destroy]

  before_filter :authorise_as_report_owner
  before_filter :confirm_spresult_in_report, :only => [:update, :destroy]

	respond_to :json

  def handleAnswer(answer,input,spresult)
      form = answer.question.form
      if form == 'fillin' or form == 'number'
        answer.update_attributes(input)
      elsif form.start_with?('date')
        #CHRONIC CANT TAKE PM, MAKE PEOPLE GIVE IN 24HR
        Time.zone = @report.survey.time_zone
        Chronic.time_class = Time.zone
        parsed_chron = Chronic.parse(input['stamp'])
        answer.stamp = parsed_chron
      else
        if answer.points.exists?
          answer.points.destroy_all
        end
        
        points = input['points']

        points.each do |point|
          newpoint = answer.points.build(point)
        end
        if spresult
          spresult.status = true
        end
      end
      answer.save
  end

  def index
    result = Rails.cache.fetch("controllers/spresult_index_#{@report.id}", :expires_in => 2.hours) do 
      @spresults = Spresult.where(:report_id => @report).includes(:answers => [:points]).order{answers.question_id}
      render_to_string locals: {spresults: @spresults, report: @report}
    end
    render :json => result
  end

  def show
    @spresult = Spresult.includes(:answers => [:points]).find(params[:id])
    respond_with @spresult
  end

  def update
    answers = params[:answers]

    available_ids = @spresult.all_answer_ids
    answers.each do |answer|
      if available_ids.include?(answer['id'])
        thisanswer = Answer.find(answer['id'])
        handleAnswer(thisanswer, answer, @spresult)
      else
         render :text => "Forbidden", :status => 403
      end
    end

    @spresult.save
    @report.flush() #updates report status, if we are finished.
    @spresult = Spresult.includes(:answers => [:points]).find(params[:id])
    render :json => @spresult
  end

  def create
  	@spresult = @report.spresults.create(:status => true, :uid => params[:uid])

  	answers = params[:answers]

  	answers.each do |answer|
  		thisanswer = @spresult.answers.create()
      thisquestion = Question.find(answer['question_id'])
  		thisanswer.question = thisquestion
      handleAnswer(thisanswer, answer, nil)
  	end

    respond_with(@spresult, :location => nil)
  end

  def destroy
    respond_with(@spresult.destroy)
  end

  private

  def fetch_report
    @report = Report.find(params[:report_id])
    rescue ActiveRecord::RecordNotFound
      render :text => "Not Found", :status => 404
  end

  def authorise_as_report_owner
     unless @report.user == current_user
        render :text => "Forbidden", :status => 403
     end
  end

  def fetch_spresult
    @spresult = Spresult.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => "Not Found", :status => 404
  end

  def confirm_spresult_in_report
    unless @spresult.report.id == @report.id
        render :text => "Forbidden", :status => 403
    end
  end


end
