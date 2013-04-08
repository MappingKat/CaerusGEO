require 'spec_helper'

describe CollaboratorsController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @survey = FactoryGirl.create(:survey)
    @survey.user = @user
    @survey.save

    @collab = FactoryGirl.build(:collaborator)
    @collab.email = "someguy@gmail.com"
    @collab.survey = @survey
    @collab.save



    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")
    @othersurvey = FactoryGirl.create(:survey)
    @othersurvey.user = @otheruser
    @othersurvey.save
  end

  context "JSON" do

    describe "GET 'index'" do
      it "returns http success" do
        get :index, :survey_id => @survey.id, :format => :json
        response.should be_success
      end
    end

    describe "GET 'index'" do
      it "should fail if it isnt my survey" do
        get :index, :survey_id => @othersurvey.id
        response.should_not be_success
      end
    end

    describe "POST 'create'" do
      it "it should suceed if its my survey" do
        post 'create', :survey_id => @survey.id ,:email => "roger@basic.com", :format => :json
        response.should be_success
      end
    end

    describe "POST 'create'" do
      it "it should fail without an email" do
        post 'create', :survey_id => @survey.id, :format => :json
        response.should_not be_success
      end
    end

    describe "POST 'create'" do
      it "it should fail if it isn't my survey" do
        post 'create', :survey_id => @othersurvey.id ,:email => "roger@basic.com", :format => :json
        response.should_not be_success
      end
    end

    describe "POST 'create'" do
      it "it should fail if survey doesnt exist" do
        post 'create', :survey_id => 73 ,:email => "roger@basic.com", :format => :json
        response.should_not be_success
      end
    end

    describe "DELETE 'destroy'" do
      it "returns http success" do
        delete 'destroy', :id => @collab.id, :survey_id => @survey.id, :format => :json
        response.should be_success
      end
    end

  end

end
