require 'spec_helper'

describe SpresultsController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @survey = FactoryGirl.create(:survey, user: @user)
    @report = FactoryGirl.create(:report, survey: @survey, user: @user)
    @spresult = FactoryGirl.create(:spresult, report: @report)

    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")
    @othersurvey = FactoryGirl.create(:survey, user: @otheruser)
    @otherreport = FactoryGirl.create(:report, survey: @othersurvey, user: @otheruser)
    @otherspresult = FactoryGirl.create(:spresult, report: @otherreport)

  end

  context "JSON" do

    describe "GET 'index'" do
      it "returns http success" do
        get 'index', :report_id => @report.id, :survey_id => @report.survey.id, :format => :json
        response.should be_success
      end

      it "returns http forbidden if its not my report/survey" do
        get 'index', :report_id => @otherreport.id, :survey_id => @report.survey.id, :format => :json
        response.code.should eq("403")
      end
    end

    describe "GET 'show'" do
      it "returns http success" do
        get 'show', :id => @spresult.id, :report_id => @report.id, :survey_id => @report.survey.id, :format => :json
        response.should be_success
      end

      it "returns http forbidden if its not mine" do
        get 'show', :id => @otherspresult.id, :report_id => @otherreport.id, :survey_id => @otherreport.survey.id, :format => :json
        response.code.should eq("403")
      end
    end

    describe "POST 'create'" do
      it "returns http success" do
        post :create, :report_id => @report.id, :survey_id => @report.survey.id, :answers => [], :format => :json
        response.should be_success
      end

      it "returns http forbidden if its not my report/survey" do
        post :create, :report_id => @otherreport.id, :survey_id => @otherreport.survey.id, :answers => [], :format => :json
        response.code.should eq("403")
      end
    end

    describe "PUT 'update'" do
      it "returns http forbidden if its not my report/survey" do
        put :update, :id => @otherspresult.id, :report_id => @otherreport.id, :survey_id => @otherreport.survey.id, :format => :json
        response.code.should eq("403")
      end
    end

  end

end
