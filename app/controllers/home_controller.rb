class HomeController < ApplicationController
  def index
    if current_user
    	redirect_to current_user
    end
  end

  def about
  
  end

  def error

  end

  def terms 

  end

  def help

  end

  def team

  end
end
