require 'spec_helper'

describe SurveysController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @survey = FactoryGirl.create(:survey)
    @survey.user = @user
    @survey.save

    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")
    @othersurvey = FactoryGirl.create(:survey)
    @othersurvey.public = true
    @othersurvey.user = @otheruser
    @othersurvey.save
  end

  describe "GET 'show'" do
    
    it "SHOW should be successful" do
      get :show, :id => @survey.id
      response.should be_success
    end

    it "ANALYZE should be successful" do
      get :analyze, :id => @survey.id
      response.should be_success
    end
    
    it "SHOW should find the right survey" do
      get :show, :id => @survey.id
      assigns(:survey).should == @survey
    end

    it "should forbid if not allowed" do
      get :show, :id => @othersurvey.id
      response.should_not be_success
    end

    it "a survey thats public should be viewable by the public" do
      sign_out @user
      get :public, :id => @othersurvey.id
      response.should be_success
    end

    it "a survey thats not public should not be viewable by the public" do
      sign_out @user
      get :public, :id => @survey.id
      response.code.should eq("401")
    end


    
  end

end
