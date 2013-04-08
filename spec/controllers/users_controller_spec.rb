require 'spec_helper'

describe UsersController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user


    @otheruser = FactoryGirl.create(:user, email: "roger@bds.com",name: "Roger B")

  end

  

  describe "GET 'show'" do
    
    it "should be successful" do
      get :show, :id => @user.id
      response.should be_success
    end
    
    it "should find the right user" do
      get :show, :id => @user.id
      assigns(:user).should == @user
    end

    it "should fail if not me" do
      get :show, :id => @otheruser.id
      response.should_not be_success
    end

    it "should fail if user doesnt exist" do
      get :show, :id => 321
      response.code.should eq('404')
    end
    
  end

end
