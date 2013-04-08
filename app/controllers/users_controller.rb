class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :fetch_user

  def show
    #TODO Convert to filter
    if @user != current_user 
    	respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, you can't view this user."
            render :template => "home/error", :status => 401
          }
        end 
    end

  end

  private

  def fetch_user
    @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
          format.html {
            flash[:notice] = "Sorry, this user doesn't exist."
            render :template => "home/error", :status => 404
          }
      end 
  end

end
