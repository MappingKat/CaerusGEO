class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :instantiate_controller_and_action_names, :mailer_set_url_options

  around_filter :user_time_zone, if: :current_user

 
  #Use for active/inactive css.
  def instantiate_controller_and_action_names
      @current_action = action_name
      @current_controller = controller_name
  end

  #Geocoder for "locate" pages
  def find_location
    @location = Geocoder.search(params[:location])[0]
    respond_to do |format|
      format.json { render json: @location }
    end
  end

  def geolocate_via_ip
    @location = Geocoder.search(request.ip)[0]
    respond_to do |format|
      format.json { render json: @location }
    end
  end

  def mailer_set_url_options
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

  private
  
  def user_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end
end
