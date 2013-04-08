require 'spec_helper'

describe ReportsController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @survey = FactoryGirl.create(:survey)
    @survey.user = @user
    @survey.save

    @report = FactoryGirl.create(:report, :survey => @survey,:user => @user)
    @report.save

    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")
    @othersurvey = FactoryGirl.create(:survey)
    @othersurvey.user = @otheruser
    @othersurvey.save

    @otherreport = FactoryGirl.create(:report, :survey => @othersurvey,:user => @otheruser)
    @otherreport.save
  end

  it "creating should be successful if I own the survey or are collaborating on it." do
      post :create, :survey_id => @survey.id, :title => "hi"
      response.code.should eq("302")
  end

  it "creating shouldnt be successful if I don't own survey and I'm not collaborating on it." do
      post :create, :survey_id => @otheruser.id, :title => "hi"
      response.code.should eq("401")
  end

  it "should be successful" do
      get :edit, :id => @report.id, :survey_id => @report.survey.id
      response.should be_success
  end

  it "should fail if its not my survey" do
      get :edit, :id => @otherreport.id, :survey_id => @otherreport.survey.id
      response.should_not be_success
  end

  
end
