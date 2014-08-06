class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def current_user
    @current_user = nil

    if user_id = session[:user_id]
      @current_user = User.find(user_id)
    end

    @current_user 
  end

  helper_method :current_user
end
