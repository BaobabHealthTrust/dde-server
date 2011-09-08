class LoginsController < ApplicationController

  def show
    
  end

  def create
    user = User.find_by_name params[:name]
    if user.password_matches?(params[:password])
      login! user
      redirect_to back_or_default
    else
      render :action => 'show'
    end
  end

  def logout
    logout!
    redirect_to :action => show, referrer_param => referrer
  end

  protected

  def default_path
    people_path
  end

  def perform_basic_auth
    authorize! :access, :login
  end

  def access_denied
    redirect_to default_path
  end
end
