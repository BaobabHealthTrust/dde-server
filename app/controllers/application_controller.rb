class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :perform_basic_auth

  rescue_from CanCan::AccessDenied,
      :with => :access_denied

  helper_method :current_user

  protected

  # some common auth related stubs, can later be replaced by any
  # more sophisticated auth system if we want/need
  def login!(user)
    session[:current_user_id] = user.id
    @current_user = user
  end

  def logout!
    session[:current_user_id] = nil
    @current_user = nil
  end

  def current_user
    unless @current_user == false # meaning a user has previously been established as not logged in
      @current_user ||= authenticate_from_session || authenticate_from_basic_auth || false
    end
  end

  def authenticate_from_basic_auth
    authenticate_with_http_basic do |user_name, password|
      user = User.find_by_name(user_name)
      if user and user.password_matches?(password)
        return user
      else
        return false
      end
    end
  end

  def authenticate_from_session
    unless session[:current_user_id].blank?
      return User.where(:id => session[:current_user_id]).first
    end
  end

  def perform_basic_auth
    authorize! :access, :anyhing
  end

  def access_denied
    redirect_to login_path(referrer_param => current_path)
  end

end
