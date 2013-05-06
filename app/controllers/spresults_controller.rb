class SpresultsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :fetch_report
  before_filter :authorise_as_report_owner


	respond_to :json

  def index
  	@report = Report.find(params[:report_id])
  	#respond_with @report.spresults.map(&:id)
    respond_with @report.spresults.order{answers.question_id}.includes(:answers => [:points])
  end

  def show
    @report = Report.find(params[:report_id])
    @spresult = Spresult.includes(:answers => [:points]).find(params[:id])
    respond_with @spresult
  end

  def update
    @report = Report.find(params[:report_id])

    @spresult = Spresult.find(params[:id])
    #add protection that answer belongs to this spresult!
    answers = params[:answers]

    answers.each do |answer|
      thisanswer = Answer.find(answer['id'])
      if thisanswer.question.form.start_with?('geo')
          points = answer['points']
          points.each do |point|
            newpoint = thisanswer.points.build(point)
          end
        thisanswer.save
      else
        #We don't support updating of other questions yet.those fillins are done before uploading.

        #  thisanswer.update_attributes(answer)
        thisq = Question.find(thisanswer.question.id)
        thisq.wipe_caches()
      end

    end
    @spresult.status = true
    @spresult.save
    @report.flush() #updates report status, if we are finished.
    respond_with @spresult
  end

  def create
  	@report = Report.find(params[:report_id])
  	@spresult = @report.spresults.create(:status => true)

  	answers = params[:answers]

  	answers.each do |answer|
  		thisanswer = @spresult.answers.create()
      thisquestion = Question.find(answer['question_id'])
  		thisanswer.question = thisquestion
      form = thisquestion.form
  		if form=='fillin' or form=='number'
  			thisanswer.update_attributes(answer)
        thisanswer.question.wipe_caches()

      elsif form.start_with?('date')
        #CHRONIC CANT TAKE PM, MAKE PEOPLE GIVE IN 24HR
        Time.zone = @report.survey.time_zone
        Chronic.time_class = Time.zone
        parsed_chron = Chronic.parse(answer['stamp'])
        thisanswer.stamp = parsed_chron
  		else
  			points = answer['points']

  			points.each do |point|
  				newpoint = thisanswer.points.build(point)
  			end 
  		end
  		thisanswer.save

  	end

    respond_with(@spresult, :location => "")
  end

  def destroy
  end

  private

  def fetch_report
    @report = Report.find(params[:report_id])
    rescue ActiveRecord::RecordNotFound
      render :text => "Not Found", :status => 404
  end

  def authorise_as_report_owner
     unless @report.user == current_user
        #You don't belong here. Go away.
        render :text => "Forbidden", :status => 401
     end
  end


end
