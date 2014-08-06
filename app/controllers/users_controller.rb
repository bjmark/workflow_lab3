class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def login
    session[:user_id] = User.find(params[:id])
    redirect_to '/users'
  end
end
