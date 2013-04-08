require 'spec_helper'

describe SpresultsController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @survey = FactoryGirl.create(:survey)
    @survey.user = @user
    @survey.save

    @report = FactoryGirl.create(:report)
    @report.survey = @survey
    @report.user = @user
    @report.save

    @spresult = FactoryGirl.create(:spresult, :report => @report)

    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")
    @othersurvey = FactoryGirl.create(:survey)
    @othersurvey.user = @otheruser
    @othersurvey.save
  end

  context "JSON" do

    describe "GET 'index'" do
      it "returns http success" do
        get 'index', :report_id => @report.id, :survey_id => @report.survey.id, :format => :json
        response.should be_success
      end
    end

  end

end
